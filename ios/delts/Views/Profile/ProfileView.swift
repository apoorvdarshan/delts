import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = profiles.first {
                    ProfileEditorView(profile: profile)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 18)
                } else {
                    GlassCard {
                        Text("Creating your default profile...")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .deltsScreen()
            .contentMargins(.bottom, 110, for: .scrollContent)
            .toolbar(.hidden, for: .navigationBar)
            .onDisappear {
                try? modelContext.save()
            }
        }
    }
}

private struct ProfileEditorView: View {
    @Bindable var profile: UserProfile

    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    private let durationOptions = [30, 45, 60, 90]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            profileSnapshot
            identitySection
            goalSection
            scheduleSection
            equipmentSection
            strengthSection
            issuesSection
        }
    }

    private var header: some View {
        DeltsHeader(
            eyebrow: "Profile",
            title: profile.name.isEmpty ? "Training Profile" : profile.name,
            subtitle: "Saved locally with SwiftData. This shapes plans and equipment recommendations.",
            trailingSystemImage: "person.crop.circle.fill"
        )
    }

    private var profileSnapshot: some View {
        GlassCard(padding: 16, cornerRadius: 24) {
            HStack(spacing: 14) {
                DeltsProgressRing(
                    progress: bodyFatProgress,
                    label: "Body Fat",
                    tint: .deltsInferno
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(profile.mainGoal.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(profile.experienceLevel.title) - \(profile.workoutSplit.title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    HStack(spacing: 8) {
                        miniPill("\(profile.workoutFrequencyPerWeek)x/week", "calendar", .deltsAccent)
                        miniPill("\(profile.workoutDurationMinutes)m", "timer", .deltsGold)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var identitySection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionTitle("Body profile", systemImage: "person.crop.circle")
                ProfileTextField(title: "Name", text: $profile.name)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Gender")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Picker("Gender", selection: genderBinding) {
                        ForEach(genderOptions, id: \.self) { gender in
                            Text(gender).tag(gender)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.deltsAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.deltsPanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                IntStepperField(title: "Age", value: ageBinding, range: 13...90)

                HStack(spacing: 12) {
                    ProfileNumberField(title: "Height", suffix: "cm", value: heightBinding)
                    ProfileNumberField(title: "Weight", suffix: "kg", value: weightBinding)
                }

                HStack(spacing: 12) {
                    ProfileNumberField(title: "Current body fat", suffix: "%", value: currentBodyFatBinding)
                    ProfileNumberField(title: "Desired body fat", suffix: "%", value: desiredBodyFatBinding)
                }
            }
        }
    }

    private var goalSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionTitle("Goals", systemImage: "target")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Experience")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Picker("Experience", selection: experienceBinding) {
                        ForEach(ExperienceLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Main goal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Picker("Main goal", selection: mainGoalBinding) {
                        ForEach(FitnessGoal.profileCases) { goal in
                            Text(goal.title).tag(goal)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.deltsAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.deltsPanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Body parts to build")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    MultiSelectChipGrid(
                        options: BodyFocus.allCases,
                        selection: bodyFocusBinding,
                        title: { $0.title },
                        icon: { $0.icon }
                    )
                }

                ProfileTextField(title: "Extra goals", text: $profile.extraGoals, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }

    private var scheduleSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionTitle("Schedule", systemImage: "calendar")
                IntStepperField(
                    title: "Workout frequency",
                    value: frequencyBinding,
                    range: 1...7,
                    suffix: "days/week"
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Workout split")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Picker("Workout split", selection: splitBinding) {
                        ForEach(WorkoutSplit.allCases) { split in
                            Text(split.title).tag(split)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.deltsAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.deltsPanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Workout duration")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Picker("Workout duration", selection: durationBinding) {
                        ForEach(durationOptions, id: \.self) { duration in
                            Text("\(duration) min").tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var equipmentSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    sectionTitle("Equipment", systemImage: "dumbbell.fill")
                    Spacer()
                    Text("\(profile.availableEquipment.count) selected")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                EquipmentGrid(selection: equipmentBinding)
            }
        }
    }

    private var strengthSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionTitle("1RM numbers", systemImage: "scalemass.fill")
                HStack(spacing: 12) {
                    ProfileNumberField(title: "Bench Press", suffix: "kg", value: benchBinding)
                    ProfileNumberField(title: "Squat", suffix: "kg", value: squatBinding)
                }
                HStack(spacing: 12) {
                    ProfileNumberField(title: "Deadlift", suffix: "kg", value: deadliftBinding)
                    ProfileNumberField(title: "Overhead Press", suffix: "kg", value: overheadPressBinding)
                }
            }
        }
    }

    private var issuesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Friction points", systemImage: "exclamationmark.triangle")
                MultiSelectChipGrid(
                    options: FitnessIssue.allCases,
                    selection: issuesBinding,
                    title: { $0.title },
                    icon: { $0.icon }
                )
            }
        }
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.deltsAccent)
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
        }
    }

    private var bodyFatProgress: Double {
        guard profile.currentBodyFatPercentage > 0 else {
            return 0.75
        }

        let current = profile.currentBodyFatPercentage
        let desired = max(profile.desiredBodyFatPercentage, 1)
        return min(max(desired / current, 0.08), 1)
    }

    private func miniPill(_ text: String, _ systemImage: String, _ tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption.weight(.black))
        .foregroundStyle(.primary)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(tint.opacity(0.12), in: Capsule())
    }

    private var genderBinding: Binding<String> {
        Binding {
            profile.gender
        } set: { newValue in
            profile.gender = newValue
            profile.updatedAt = Date()
        }
    }

    private var ageBinding: Binding<Int> {
        Binding {
            profile.age
        } set: { newValue in
            profile.age = newValue
            profile.updatedAt = Date()
        }
    }

    private var heightBinding: Binding<Double> {
        doubleBinding(\.heightCM)
    }

    private var weightBinding: Binding<Double> {
        doubleBinding(\.currentWeightKG)
    }

    private var currentBodyFatBinding: Binding<Double> {
        doubleBinding(\.currentBodyFatPercentage)
    }

    private var desiredBodyFatBinding: Binding<Double> {
        doubleBinding(\.desiredBodyFatPercentage)
    }

    private var experienceBinding: Binding<ExperienceLevel> {
        Binding {
            profile.experienceLevel
        } set: { newValue in
            profile.experienceLevel = newValue
        }
    }

    private var mainGoalBinding: Binding<FitnessGoal> {
        Binding {
            profile.mainGoal
        } set: { newValue in
            profile.mainGoal = newValue
        }
    }

    private var bodyFocusBinding: Binding<Set<BodyFocus>> {
        Binding {
            profile.selectedBodyFocus
        } set: { newValue in
            profile.selectedBodyFocus = newValue
        }
    }

    private var frequencyBinding: Binding<Int> {
        Binding {
            profile.workoutFrequencyPerWeek
        } set: { newValue in
            profile.workoutFrequencyPerWeek = newValue
            profile.updatedAt = Date()
        }
    }

    private var splitBinding: Binding<WorkoutSplit> {
        Binding {
            profile.workoutSplit
        } set: { newValue in
            profile.workoutSplit = newValue
        }
    }

    private var durationBinding: Binding<Int> {
        Binding {
            profile.workoutDurationMinutes
        } set: { newValue in
            profile.workoutDurationMinutes = newValue
            profile.updatedAt = Date()
        }
    }

    private var equipmentBinding: Binding<Set<Equipment>> {
        Binding {
            profile.availableEquipment
        } set: { newValue in
            profile.availableEquipment = newValue
        }
    }

    private var benchBinding: Binding<Double> {
        doubleBinding(\.benchPressOneRM)
    }

    private var squatBinding: Binding<Double> {
        doubleBinding(\.squatOneRM)
    }

    private var deadliftBinding: Binding<Double> {
        doubleBinding(\.deadliftOneRM)
    }

    private var overheadPressBinding: Binding<Double> {
        doubleBinding(\.overheadPressOneRM)
    }

    private var issuesBinding: Binding<Set<FitnessIssue>> {
        Binding {
            profile.fitnessIssues
        } set: { newValue in
            profile.fitnessIssues = newValue
        }
    }

    private func doubleBinding(_ keyPath: ReferenceWritableKeyPath<UserProfile, Double>) -> Binding<Double> {
        Binding {
            profile[keyPath: keyPath]
        } set: { newValue in
            profile[keyPath: keyPath] = newValue
            profile.updatedAt = Date()
        }
    }
}
