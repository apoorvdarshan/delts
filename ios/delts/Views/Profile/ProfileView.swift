import Foundation
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
                    ProfileLoadingView()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                try? modelContext.save()
            }
        }
    }
}

private struct ProfileEditorView: View {
    @Bindable var profile: UserProfile
    @State private var geminiAPIKey = LocalGeminiKeyStore.apiKey ?? ""
    @State private var hasSavedGeminiKey = GeminiConfig.hasAPIKey

    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    private let durationOptions = [30, 45, 60, 90]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProfileScreenHeader()
                ProfileHero(profile: profile)
                identitySection
                goalSection
                aiSettingsSection
                bodyFocusSection
                scheduleSection
                equipmentSection
                strengthSection
                issuesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 18)
        }
        .deltsScreen()
        .contentMargins(.bottom, 110, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .tint(Color.deltsAccent)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var identitySection: some View {
        ProfileSection(
            title: "Body Profile",
            subtitle: "Used to shape plans and recommendations.",
            systemImage: "person.text.rectangle"
        ) {
            ProfileRowStack {
                ProfileTextInputRow(title: "Name", systemImage: "person.fill", text: nameBinding)
                ProfileDivider()
                ProfileMenuPicker(
                    title: "Gender",
                    systemImage: "person.2",
                    selection: genderBinding,
                    options: genderOptions,
                    label: { $0 }
                )
                ProfileDivider()
                ProfileStepperRow(title: "Age", systemImage: "calendar", value: ageBinding, range: 13...90)
                ProfileDivider()
                ProfileNumberInputRow(title: "Height", systemImage: "ruler", suffix: "cm", value: heightBinding)
                ProfileDivider()
                ProfileNumberInputRow(title: "Weight", systemImage: "scalemass", suffix: "kg", value: weightBinding)
                ProfileDivider()
                ProfileNumberInputRow(title: "Current body fat", systemImage: "percent", suffix: "%", value: currentBodyFatBinding)
                ProfileDivider()
                ProfileNumberInputRow(title: "Desired body fat", systemImage: "scope", suffix: "%", value: desiredBodyFatBinding)
            }
        }
    }

    private var goalSection: some View {
        ProfileSection(
            title: "Goals",
            subtitle: "Set the training bias before plans are generated.",
            systemImage: "scope"
        ) {
            ProfileRowStack {
                ProfileSegmentedPicker(
                    title: "Experience",
                    systemImage: "chart.line.uptrend.xyaxis",
                    selection: experienceBinding,
                    options: ExperienceLevel.allCases,
                    label: { $0.title }
                )
                ProfileDivider()
                ProfileMenuPicker(
                    title: "Main goal",
                    systemImage: "flag.checkered",
                    selection: mainGoalBinding,
                    options: FitnessGoal.profileCases,
                    label: { $0.title }
                )
                ProfileDivider()
                ProfileTextAreaRow(title: "Extra goals", systemImage: "text.alignleft", text: extraGoalsBinding)
            }
        }
    }

    private var aiSettingsSection: some View {
        ProfileSection(
            title: "AI Settings",
            subtitle: "Gemini BYOK stays on this device.",
            systemImage: "key.fill",
            badge: hasSavedGeminiKey ? "Ready" : "Local"
        ) {
            GeminiKeySettingsCard(
                apiKey: $geminiAPIKey,
                hasSavedKey: hasSavedGeminiKey,
                save: saveGeminiKey,
                clear: clearGeminiKey
            )
        }
    }

    private var bodyFocusSection: some View {
        ProfileSection(
            title: "Body Parts To Build",
            subtitle: "Choose the areas your workouts should emphasize.",
            systemImage: "figure.strengthtraining.functional",
            badge: "\(profile.selectedBodyFocus.count)"
        ) {
            ProfileChecklistGrid(
                options: BodyFocus.allCases,
                selection: bodyFocusBinding,
                title: { $0.title },
                icon: { $0.icon }
            )
        }
    }

    private var scheduleSection: some View {
        ProfileSection(
            title: "Schedule",
            subtitle: "Tune how training fits into the week.",
            systemImage: "calendar.badge.clock"
        ) {
            ProfileRowStack {
                ProfileStepperRow(
                    title: "Workout frequency",
                    systemImage: "calendar",
                    value: frequencyBinding,
                    range: 1...7,
                    suffix: "days/week"
                )
                ProfileDivider()
                ProfileMenuPicker(
                    title: "Workout split",
                    systemImage: "square.split.2x2",
                    selection: splitBinding,
                    options: WorkoutSplit.allCases,
                    label: { $0.title }
                )
                ProfileDivider()
                ProfileSegmentedPicker(
                    title: "Workout duration",
                    systemImage: "timer",
                    selection: durationBinding,
                    options: durationOptions,
                    label: { "\($0) min" }
                )
            }
        }
    }

    private var equipmentSection: some View {
        ProfileSection(
            title: "Equipment Library",
            subtitle: "Select gear here only. Start uses this saved library.",
            systemImage: "dumbbell.fill",
            badge: "\(profile.availableEquipment.count)"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                ProfileCountSummaryRow(
                    title: "Selected",
                    systemImage: "checklist",
                    value: "\(profile.availableEquipment.count)"
                )

                ProfileChecklistGrid(
                    options: Equipment.allCases,
                    selection: equipmentBinding,
                    title: { $0.title },
                    icon: { $0.icon }
                )
            }
        }
    }

    private var strengthSection: some View {
        ProfileSection(
            title: "1RM Numbers",
            subtitle: "Optional strength anchors for load guidance.",
            systemImage: "scalemass.fill"
        ) {
            ProfileRowStack {
                ProfileNumberInputRow(
                    title: "Bench Press",
                    systemImage: "figure.strengthtraining.traditional",
                    suffix: "kg",
                    value: benchBinding
                )
                ProfileDivider()
                ProfileNumberInputRow(
                    title: "Squat",
                    systemImage: "figure.strengthtraining.functional",
                    suffix: "kg",
                    value: squatBinding
                )
                ProfileDivider()
                ProfileNumberInputRow(
                    title: "Deadlift",
                    systemImage: "figure.core.training",
                    suffix: "kg",
                    value: deadliftBinding
                )
                ProfileDivider()
                ProfileNumberInputRow(
                    title: "Overhead Press",
                    systemImage: "arrow.up",
                    suffix: "kg",
                    value: overheadPressBinding
                )
            }
        }
    }

    private var issuesSection: some View {
        ProfileSection(
            title: "Friction Points",
            subtitle: "Flag what usually gets in the way.",
            systemImage: "exclamationmark.triangle.fill",
            badge: "\(profile.fitnessIssues.count)"
        ) {
            ProfileChecklistGrid(
                options: FitnessIssue.allCases,
                selection: issuesBinding,
                title: { $0.title },
                icon: { $0.icon }
            )
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

    private func saveGeminiKey() {
        LocalGeminiKeyStore.save(geminiAPIKey)
        geminiAPIKey = LocalGeminiKeyStore.apiKey ?? ""
        hasSavedGeminiKey = GeminiConfig.hasAPIKey
    }

    private func clearGeminiKey() {
        LocalGeminiKeyStore.clear()
        geminiAPIKey = ""
        hasSavedGeminiKey = false
    }
}

private struct ProfileScreenHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Setup")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.deltsAccent)
                .textCase(.uppercase)

            Text("Profile")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.deltsCharcoal)

            Text("Training defaults and saved equipment.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GeminiKeySettingsCard: View {
    @Binding var apiKey: String
    let hasSavedKey: Bool
    let save: () -> Void
    let clear: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: hasSavedKey ? "checkmark.seal.fill" : "bolt.slash.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(hasSavedKey ? Color.deltsAccent : Color.deltsWarning)
                    .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Gemini Key")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                    Text(hasSavedKey ? "Saved on device" : "Offline planner")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                }

                Spacer(minLength: 8)
            }

            SecureField("Paste API key", text: $apiKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.password)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(save)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Color.deltsPanel.opacity(0.20), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.deltsHairline.opacity(isFocused ? 0.58 : 0.30), lineWidth: 0.75)
                }

            HStack(spacing: 10) {
                Button("Clear", action: clear)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button("Save Key", action: save)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsOnAccent)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(Color.deltsAccent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .deltsPressable()
        }
        .padding(.vertical, 4)
    }
}

private struct ProfileLoadingView: View {
    var body: some View {
        ScrollView {
            HStack(alignment: .center, spacing: 14) {
                ProgressView()
                    .tint(Color.deltsAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Creating your default profile")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.deltsCharcoal)

                    Text("This only takes a moment.")
                        .font(.subheadline)
                        .foregroundStyle(Color.deltsMutedText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
        .deltsScreen()
        .contentMargins(.bottom, 110, for: .scrollContent)
    }
}

private struct ProfileHero: View {
    let profile: UserProfile
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var displayName: String {
        let trimmedName = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Athlete" : trimmedName
    }

    private var metricColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.adaptive(minimum: 220), spacing: 12, alignment: .top)]
        }
        return Array(repeating: GridItem(.flexible(minimum: 66), spacing: 10, alignment: .top), count: 4)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "person.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.deltsAccent)
                    .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 6) {
                    Text(displayName)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.deltsCharcoal)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Text("\(profile.experienceLevel.title) - \(profile.mainGoal.title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if !dynamicTypeSize.isAccessibilitySize {
                    Label("Local", systemImage: "lock.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.deltsSecondaryAccent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.deltsSecondaryAccent.opacity(0.12), in: Capsule())
                }
            }

            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 12) {
                    ProfileHeroMetric(title: "Weekly", value: "\(profile.workoutFrequencyPerWeek)x", systemImage: "calendar")
                    ProfileHeroMetric(title: "Duration", value: "\(profile.workoutDurationMinutes) min", systemImage: "timer")
                    ProfileHeroMetric(title: "Gear", value: "\(profile.availableEquipment.count)", systemImage: "dumbbell.fill")
                    ProfileHeroMetric(title: "Focus", value: "\(profile.selectedBodyFocus.count)", systemImage: "scope")
                }
            } else {
                HStack(spacing: 0) {
                    ProfileHeroMetric(title: "Weekly", value: "\(profile.workoutFrequencyPerWeek)x", systemImage: "calendar")
                    ProfileHeroMetric(title: "Duration", value: "\(profile.workoutDurationMinutes) min", systemImage: "timer")
                    ProfileHeroMetric(title: "Gear", value: "\(profile.availableEquipment.count)", systemImage: "dumbbell.fill")
                    ProfileHeroMetric(title: "Focus", value: "\(profile.selectedBodyFocus.count)", systemImage: "scope")
                }
            }
        }
        .padding(.bottom, 1)
    }
}

private struct ProfileHeroMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 16, height: 18, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProfileSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let badge: String?
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        badge: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.badge = badge
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Rectangle()
                .fill(Color.deltsHairline.opacity(0.42))
                .frame(height: 0.5)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.deltsAccent)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(Color.deltsMutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 10)

                if let badge {
                    Text(badge)
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.deltsAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.deltsAccent.opacity(0.11), in: Capsule())
                }
            }

            content
        }
    }
}

private struct ProfileRowStack<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
    }
}

private struct ProfileDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.28))
            .frame(height: 0.5)
            .padding(.leading, 48)
    }
}

private struct ProfileFieldLabel: View {
    let title: String
    let systemImage: String
    var tint: Color = .deltsSecondaryAccent

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)

            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ProfileFieldRow<Content: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    let content: Content
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        title: String,
        systemImage: String,
        tint: Color = .deltsSecondaryAccent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                ProfileFieldLabel(title: title, systemImage: systemImage, tint: tint)
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        } else {
            HStack(alignment: .center, spacing: 12) {
                ProfileFieldLabel(title: title, systemImage: systemImage, tint: tint)
                    .layoutPriority(1)

                Spacer(minLength: 12)

                content
                    .layoutPriority(2)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
    }
}

private struct ProfileControlBlock<Content: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    let content: Content

    init(
        title: String,
        systemImage: String,
        tint: Color = .deltsSecondaryAccent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProfileFieldLabel(title: title, systemImage: systemImage, tint: tint)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
    }
}

private struct ProfileTextInputRow: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            TextField(title, text: $text)
                .textFieldStyle(.plain)
                .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
                .foregroundStyle(Color.deltsCharcoal)
                .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 0 : 120)
                .textInputAutocapitalization(.words)
        }
    }
}

private struct ProfileTextAreaRow: View {
    let title: String
    let systemImage: String
    @Binding var text: String

    var body: some View {
        ProfileControlBlock(title: title, systemImage: systemImage) {
            TextField(title, text: $text, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.deltsCharcoal)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.deltsHairline.opacity(0.28), lineWidth: 0.5)
                }
        }
    }
}

private struct ProfileNumberInputRow: View {
    let title: String
    let systemImage: String
    let suffix: String
    @Binding var value: Double
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                TextField(title, value: $value, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
                    .textFieldStyle(.plain)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Color.deltsCharcoal)

                Text(suffix)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
            }
            .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 128, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
        }
    }
}

private struct ProfileStepperRow: View {
    let title: String
    let systemImage: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var suffix: String = ""

    private var displayValue: String {
        suffix.isEmpty ? "\(value)" : "\(value) \(suffix)"
    }

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            HStack(spacing: 12) {
                Text(displayValue)
                    .font(.body.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                ProfileStepperControl(value: $value, range: range, title: title)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
            .accessibilityValue(displayValue)
        }
    }
}

private struct ProfileStepperControl: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let title: String

    private var canDecrement: Bool {
        value > range.lowerBound
    }

    private var canIncrement: Bool {
        value < range.upperBound
    }

    var body: some View {
        HStack(spacing: 0) {
            Button {
                value = max(range.lowerBound, value - 1)
            } label: {
                Image(systemName: "minus")
                    .font(.headline.weight(.bold))
                    .frame(width: 42, height: 38)
            }
            .disabled(!canDecrement)
            .accessibilityLabel("Decrease \(title)")

            Rectangle()
                .fill(Color.deltsHairline.opacity(0.36))
                .frame(width: 0.5, height: 22)

            Button {
                value = min(range.upperBound, value + 1)
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .frame(width: 42, height: 38)
            }
            .disabled(!canIncrement)
            .accessibilityLabel("Increase \(title)")
        }
        .foregroundStyle(Color.deltsCharcoal)
        .background(Color.deltsPanel.opacity(0.34), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.5)
        }
        .deltsPressable()
    }
}

private struct ProfileMenuPicker<Option: Hashable>: View {
    let title: String
    let systemImage: String
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        if option == selection {
                            Label(label(option), systemImage: "checkmark")
                        } else {
                            Text(label(option))
                        }
                    }
                }
            } label: {
                ProfileMenuValueLabel(text: label(selection))
            }
            .deltsPressable()
        }
    }
}

private struct ProfileMenuValueLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 7) {
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.trailing)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
        }
        .padding(.horizontal, 12)
        .frame(minWidth: 104, minHeight: 40, alignment: .trailing)
        .background(Color.deltsPanel.opacity(0.36), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.36), lineWidth: 0.5)
        }
    }
}

private struct ProfileSegmentedPicker<Option: Hashable>: View {
    let title: String
    let systemImage: String
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ProfileControlBlock(title: title, systemImage: systemImage) {
            if dynamicTypeSize.isAccessibilitySize {
                Menu {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selection = option
                        } label: {
                            if option == selection {
                                Label(label(option), systemImage: "checkmark")
                            } else {
                                Text(label(option))
                            }
                        }
                    }
                } label: {
                    ProfileMenuValueLabel(text: label(selection))
                }
                .deltsPressable()
            } else {
                ProfileChoiceRail(selection: $selection, options: options, label: label)
            }
        }
    }
}

private struct ProfileChoiceRail<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == selection

                    Button {
                        let animation: Animation? = reduceMotion ? nil : .snappy(duration: 0.18)
                        withAnimation(animation) {
                            selection = option
                        }
                    } label: {
                        Text(label(option))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(isSelected ? Color.deltsOnAccent : Color.deltsCharcoal)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .padding(.horizontal, 13)
                            .frame(minWidth: 92, minHeight: 40)
                            .background(
                                isSelected ? Color.deltsAccent : Color.deltsPanel.opacity(0.24),
                                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(Color.deltsHairline.opacity(isSelected ? 0.18 : 0.30), lineWidth: 0.5)
                            }
                            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .deltsPressable()
                    .accessibilityLabel(label(option))
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

private struct ProfileCountSummaryRow: View {
    let title: String
    let systemImage: String
    let value: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ProfileFieldLabel(title: title, systemImage: systemImage)

            Spacer(minLength: 12)

            Text(value)
                .font(.headline.monospacedDigit().weight(.bold))
                .foregroundStyle(Color.deltsAccent)
        }
        .padding(.vertical, 8)
    }
}

private struct ProfileChecklistGrid<Option: Identifiable & Hashable>: View {
    let options: [Option]
    @Binding var selection: Set<Option>
    let title: (Option) -> String
    let icon: (Option) -> String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 260 : 150),
                spacing: 10,
                alignment: .top
            )
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(options) { option in
                let isSelected = selection.contains(option)

                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        var updatedSelection = selection
                        if isSelected {
                            updatedSelection.remove(option)
                        } else {
                            updatedSelection.insert(option)
                        }
                        selection = updatedSelection
                    }
                } label: {
                    ProfileChecklistChip(
                        title: title(option),
                        systemImage: icon(option),
                        isSelected: isSelected
                    )
                }
                .deltsPressable()
                .accessibilityValue(isSelected ? "Selected" : "Not selected")
                .accessibilityHint(isSelected ? "Double tap to remove." : "Double tap to select.")
            }
        }
    }
}

private struct ProfileChecklistChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsSecondaryAccent)
                .frame(width: 28, height: 28)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .minimumScaleFactor(0.86)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: isSelected ? "checkmark" : "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsHairline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .background(
            (isSelected ? Color.deltsAccent.opacity(0.11) : Color.deltsPanel.opacity(0.14)),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    isSelected ? Color.deltsAccent.opacity(0.38) : Color.deltsHairline.opacity(0.22),
                    lineWidth: 0.75
                )
        }
    }
}
