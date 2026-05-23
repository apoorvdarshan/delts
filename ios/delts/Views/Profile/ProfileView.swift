import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    ProfileEditorView(profile: profile)
                } else {
                    Form {
                        Section {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Creating your default profile...")
                            }
                        }
                    }
                    .formStyle(.grouped)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
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
        Form {
            identitySection
            goalSection
            bodyFocusSection
            scheduleSection
            equipmentSection
            strengthSection
            issuesSection
        }
        .formStyle(.grouped)
        .contentMargins(.bottom, 110, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .tint(Color.deltsAccent)
    }

    private var identitySection: some View {
        Section {
            ProfileTextField(title: "Name", text: nameBinding)

            Picker("Gender", selection: genderBinding) {
                ForEach(genderOptions, id: \.self) { gender in
                    Text(gender).tag(gender)
                }
            }
            .pickerStyle(.menu)

            IntStepperField(title: "Age", value: ageBinding, range: 13...90)
            ProfileNumberField(title: "Height", suffix: "cm", value: heightBinding)
            ProfileNumberField(title: "Weight", suffix: "kg", value: weightBinding)
            ProfileNumberField(title: "Current body fat", suffix: "%", value: currentBodyFatBinding)
            ProfileNumberField(title: "Desired body fat", suffix: "%", value: desiredBodyFatBinding)
        } header: {
            Text("Body Profile")
        } footer: {
            Text("Saved locally with SwiftData and used to shape plans and equipment recommendations.")
        }
    }

    private var goalSection: some View {
        Section {
            Picker("Experience", selection: experienceBinding) {
                ForEach(ExperienceLevel.allCases) { level in
                    Text(level.title).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Picker("Main goal", selection: mainGoalBinding) {
                ForEach(FitnessGoal.profileCases) { goal in
                    Text(goal.title).tag(goal)
                }
            }
            .pickerStyle(.menu)

            ProfileTextField(title: "Extra goals", text: extraGoalsBinding, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Goals")
        }
    }

    private var bodyFocusSection: some View {
        Section {
            MultiSelectChecklist(
                options: BodyFocus.allCases,
                selection: bodyFocusBinding,
                title: { $0.title },
                icon: { $0.icon }
            )
        } header: {
            Text("Body Parts To Build")
        }
    }

    private var scheduleSection: some View {
        Section {
            IntStepperField(
                title: "Workout frequency",
                value: frequencyBinding,
                range: 1...7,
                suffix: "days/week"
            )

            Picker("Workout split", selection: splitBinding) {
                ForEach(WorkoutSplit.allCases) { split in
                    Text(split.title).tag(split)
                }
            }
            .pickerStyle(.menu)

            Picker("Workout duration", selection: durationBinding) {
                ForEach(durationOptions, id: \.self) { duration in
                    Text("\(duration) min").tag(duration)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Schedule")
        }
    }

    private var equipmentSection: some View {
        Section {
            LabeledContent("Selected", value: "\(profile.availableEquipment.count)")

            MultiSelectChecklist(
                options: Equipment.allCases,
                selection: equipmentBinding,
                title: { $0.title },
                icon: { $0.icon }
            )
        } header: {
            Text("Equipment")
        }
    }

    private var strengthSection: some View {
        Section {
            ProfileNumberField(title: "Bench Press", suffix: "kg", value: benchBinding)
            ProfileNumberField(title: "Squat", suffix: "kg", value: squatBinding)
            ProfileNumberField(title: "Deadlift", suffix: "kg", value: deadliftBinding)
            ProfileNumberField(title: "Overhead Press", suffix: "kg", value: overheadPressBinding)
        } header: {
            Text("1RM Numbers")
        }
    }

    private var issuesSection: some View {
        Section {
            MultiSelectChecklist(
                options: FitnessIssue.allCases,
                selection: issuesBinding,
                title: { $0.title },
                icon: { $0.icon }
            )
        } header: {
            Text("Friction Points")
        }
    }

    private var genderBinding: Binding<String> {
        Binding {
            profile.gender
        } set: { newValue in
            profile.gender = newValue
            profile.updatedAt = Date()
        }
    }

    private var nameBinding: Binding<String> {
        Binding {
            profile.name
        } set: { newValue in
            profile.name = newValue
            profile.updatedAt = Date()
        }
    }

    private var extraGoalsBinding: Binding<String> {
        Binding {
            profile.extraGoals
        } set: { newValue in
            profile.extraGoals = newValue
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
            profile.updatedAt = Date()
        }
    }

    private var mainGoalBinding: Binding<FitnessGoal> {
        Binding {
            profile.mainGoal
        } set: { newValue in
            profile.mainGoal = newValue
            profile.updatedAt = Date()
        }
    }

    private var bodyFocusBinding: Binding<Set<BodyFocus>> {
        Binding {
            profile.selectedBodyFocus
        } set: { newValue in
            profile.selectedBodyFocus = newValue
            profile.updatedAt = Date()
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
            profile.updatedAt = Date()
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
            profile.updatedAt = Date()
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
            profile.updatedAt = Date()
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
