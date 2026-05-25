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

private enum MeasurementSystem: String, CaseIterable, Hashable {
    case metric
    case imperial

    var title: String {
        switch self {
        case .metric:
            return "Metric"
        case .imperial:
            return "Imperial"
        }
    }
}

private struct ProfileEditorView: View {
    @Bindable var profile: UserProfile
    @AppStorage("profile_measurement_system") private var measurementSystemRaw = MeasurementSystem.metric.rawValue
    @State private var geminiAPIKey = LocalGeminiKeyStore.apiKey ?? ""
    @State private var hasSavedGeminiKey = GeminiConfig.hasAPIKey

    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    private let ageOptions = Array(13...90)
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
            title: "About",
            subtitle: "Basic details used to shape plans.",
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
                ProfileMenuPicker(
                    title: "Age",
                    systemImage: "calendar",
                    selection: ageBinding,
                    options: ageOptions,
                    label: { "\($0)" }
                )
                ProfileDivider()
                ProfileSegmentedPicker(
                    title: "Units",
                    systemImage: "ruler",
                    selection: measurementSystemBinding,
                    options: MeasurementSystem.allCases,
                    label: { $0.title }
                )
                ProfileDivider()
                ProfileHeightPickerRow(
                    title: "Height",
                    systemImage: "ruler",
                    system: measurementSystem,
                    centimeters: heightBinding
                )
                ProfileDivider()
                ProfileWeightPickerRow(
                    title: "Weight",
                    systemImage: "scalemass",
                    system: measurementSystem,
                    kilograms: weightBinding
                )
                ProfileDivider()
                ProfilePercentPickerRow(
                    title: "Current body fat",
                    systemImage: "percent",
                    value: currentBodyFatBinding,
                    range: 3...60
                )
                ProfileDivider()
                ProfilePercentPickerRow(
                    title: "Desired body fat",
                    systemImage: "scope",
                    value: desiredBodyFatBinding,
                    range: 3...45
                )
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
            badge: hasSavedGeminiKey ? "Ready" : nil
        ) {
            ProfileRowStack {
                ProfileGeminiKeyRow(
                    apiKey: $geminiAPIKey,
                    hasSavedKey: hasSavedGeminiKey,
                    save: saveGeminiKey,
                    clear: clearGeminiKey
                )
            }
        }
    }

    private var bodyFocusSection: some View {
        ProfileSection(
            title: "Body Parts To Build",
            subtitle: "Choose the areas your workouts should emphasize.",
            systemImage: "figure.strengthtraining.functional",
            badge: "\(profile.selectedBodyFocus.count)"
        ) {
            ProfileRowStack {
                ProfileMultiSelectMenuRow(
                    title: "Focus areas",
                    systemImage: "figure.strengthtraining.functional",
                    options: BodyFocus.allCases,
                    selection: bodyFocusBinding,
                    label: { $0.title }
                )
            }
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
            ProfileRowStack {
                ProfileMultiSelectMenuRow(
                    title: "Saved gear",
                    systemImage: "dumbbell.fill",
                    options: Equipment.allCases,
                    selection: equipmentBinding,
                    label: { $0.title }
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
            ProfileRowStack {
                ProfileMultiSelectMenuRow(
                    title: "Issues",
                    systemImage: "exclamationmark.triangle.fill",
                    options: FitnessIssue.allCases,
                    selection: issuesBinding,
                    label: { $0.title }
                )
            }
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

    private var measurementSystem: MeasurementSystem {
        MeasurementSystem(rawValue: measurementSystemRaw) ?? .metric
    }

    private var measurementSystemBinding: Binding<MeasurementSystem> {
        Binding {
            measurementSystem
        } set: { newValue in
            measurementSystemRaw = newValue.rawValue
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
            return [GridItem(.adaptive(minimum: 210), spacing: 10, alignment: .top)]
        }
        return Array(repeating: GridItem(.flexible(minimum: 132), spacing: 10, alignment: .top), count: 2)
    }

    private var metrics: [(title: String, value: String, systemImage: String)] {
        [
            ("Weekly", "\(profile.workoutFrequencyPerWeek)x", "calendar"),
            ("Duration", "\(profile.workoutDurationMinutes) min", "timer"),
            ("Gear", "\(profile.availableEquipment.count)", "dumbbell.fill"),
            ("Focus", "\(profile.selectedBodyFocus.count)", "scope")
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
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
            }

            LazyVGrid(columns: metricColumns, alignment: .leading, spacing: 10) {
                ForEach(metrics, id: \.title) { metric in
                    ProfileHeroMetric(title: metric.title, value: metric.value, systemImage: metric.systemImage)
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.deltsPanel.opacity(0.50),
                            Color.deltsCard.opacity(0.26),
                            Color.deltsPanel.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .deltsLiquidBarSurface(cornerRadius: 28)
        .overlay(alignment: .topTrailing) {
            Capsule()
                .fill(Color.deltsAccent.opacity(0.42))
                .frame(width: 72, height: 4)
                .padding(.top, 12)
                .padding(.trailing, 18)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.75)
        }
    }
}

private struct ProfileHeroMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 30, height: 30)

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
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(Color.deltsBackground.opacity(0.24), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.26), lineWidth: 0.5)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(title)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 10)

                if let badge {
                    Text(badge)
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.deltsAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.deltsAccent.opacity(0.10), in: Capsule())
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

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
        .padding(.horizontal, 14)
        .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.22), lineWidth: 0.5)
        }
    }
}

private struct ProfileSectionPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.deltsPanel.opacity(0.13), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
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
                .font(.system(size: 19, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: 38, height: 34)

            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
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
            .padding(.vertical, 9)
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
        ProfileFieldRow(title: title, systemImage: systemImage) {
            TextField(title, text: $text)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.deltsCharcoal)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .frame(minWidth: 130)
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

private struct ProfileHeightPickerRow: View {
    let title: String
    let systemImage: String
    let system: MeasurementSystem
    @Binding var centimeters: Double
    @State private var isPickerPresented = false

    private var displayText: String {
        switch system {
        case .metric:
            return "\(profileFormatDecimal(centimeters)) cm"
        case .imperial:
            let parts = profileImperialHeightParts(fromCentimeters: centimeters)
            return "\(parts.feet) ft \(parts.inches) in"
        }
    }

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Button {
                isPickerPresented = true
            } label: {
                ProfileMenuValueLabel(text: displayText)
            }
            .deltsPressable()
            .sheet(isPresented: $isPickerPresented) {
                switch system {
                case .metric:
                    ProfileDecimalWheelSheet(
                        title: title,
                        initialValue: centimeters,
                        wholeRange: 120...230,
                        unit: "cm"
                    ) { newValue in
                        centimeters = newValue
                    }
                case .imperial:
                    ProfileImperialHeightWheelSheet(
                        initialCentimeters: centimeters
                    ) { newCentimeters in
                        centimeters = newCentimeters
                    }
                }
            }
        }
    }
}

private struct ProfileWeightPickerRow: View {
    let title: String
    let systemImage: String
    let system: MeasurementSystem
    @Binding var kilograms: Double
    @State private var isPickerPresented = false

    private var displayValue: Double {
        switch system {
        case .metric:
            return kilograms
        case .imperial:
            return kilograms * 2.2046226218
        }
    }

    private var unit: String {
        system == .metric ? "kg" : "lb"
    }

    private var wholeRange: ClosedRange<Int> {
        system == .metric ? 30...250 : 66...551
    }

    private var displayText: String {
        "\(profileFormatDecimal(displayValue)) \(unit)"
    }

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Button {
                isPickerPresented = true
            } label: {
                ProfileMenuValueLabel(text: displayText)
            }
            .deltsPressable()
            .sheet(isPresented: $isPickerPresented) {
                ProfileDecimalWheelSheet(
                    title: title,
                    initialValue: displayValue,
                    wholeRange: wholeRange,
                    unit: unit
                ) { newDisplayValue in
                    switch system {
                    case .metric:
                        kilograms = newDisplayValue
                    case .imperial:
                        kilograms = newDisplayValue / 2.2046226218
                    }
                }
            }
        }
    }
}

private struct ProfilePercentPickerRow: View {
    let title: String
    let systemImage: String
    @Binding var value: Double
    let range: ClosedRange<Int>
    @State private var isPickerPresented = false

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Button {
                isPickerPresented = true
            } label: {
                ProfileMenuValueLabel(text: "\(profileFormatDecimal(value))%")
            }
            .deltsPressable()
            .sheet(isPresented: $isPickerPresented) {
                ProfileDecimalWheelSheet(
                    title: title,
                    initialValue: value,
                    wholeRange: range,
                    unit: "%"
                ) { newValue in
                    value = newValue
                }
            }
        }
    }
}

private struct ProfileDecimalWheelSheet: View {
    let title: String
    let unit: String
    let wholeOptions: [Int]
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var whole: Int
    @State private var decimal: Int

    init(
        title: String,
        initialValue: Double,
        wholeRange: ClosedRange<Int>,
        unit: String,
        onSave: @escaping (Double) -> Void
    ) {
        let parts = profileDecimalParts(for: initialValue, range: wholeRange)
        self.title = title
        self.unit = unit
        self.wholeOptions = Array(wholeRange)
        self.onSave = onSave
        _whole = State(initialValue: parts.whole)
        _decimal = State(initialValue: parts.decimal)
    }

    private var selectedValue: Double {
        Double(whole) + (Double(decimal) / 10)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(profileFormatDecimal(selectedValue)) \(unit)")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 10) {
                    ProfileWheelColumn(title: "Whole", selection: $whole, values: wholeOptions) { "\($0)" }
                    ProfileWheelColumn(title: "Decimal", selection: $decimal, values: Array(0...9)) { ".\($0)" }

                    Text(unit)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText)
                        .frame(width: 48)
                }
                .frame(height: 190)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .background(DeltsBackground())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(selectedValue)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.height(340), .medium])
        .presentationDragIndicator(.visible)
    }
}

private struct ProfileImperialHeightWheelSheet: View {
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var feet: Int
    @State private var inches: Int

    init(initialCentimeters: Double, onSave: @escaping (Double) -> Void) {
        let parts = profileImperialHeightParts(fromCentimeters: initialCentimeters)
        self.onSave = onSave
        _feet = State(initialValue: parts.feet)
        _inches = State(initialValue: parts.inches)
    }

    private var selectedInches: Double {
        Double((feet * 12) + inches)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(feet) ft \(inches) in")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 8) {
                    ProfileWheelColumn(title: "Feet", selection: $feet, values: Array(3...8)) { "\($0)" }
                    ProfileWheelColumn(title: "Inches", selection: $inches, values: Array(0...11)) { "\($0)" }
                }
                .frame(height: 190)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .background(DeltsBackground())
            .navigationTitle("Height")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(selectedInches * 2.54)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.height(340), .medium])
        .presentationDragIndicator(.visible)
    }
}

private struct ProfileWheelColumn: View {
    let title: String
    @Binding var selection: Int
    let values: [Int]
    let label: (Int) -> String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)

            Picker(title, selection: $selection) {
                ForEach(values, id: \.self) { value in
                    Text(label(value))
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity)
        .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
        }
    }
}

private func profileFormatDecimal(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(1)))
}

private func profileDecimalParts(for value: Double, range: ClosedRange<Int>) -> (whole: Int, decimal: Int) {
    let minimumTenths = range.lowerBound * 10
    let maximumTenths = (range.upperBound * 10) + 9
    let tenths = Int((value * 10).rounded()).clamped(to: minimumTenths...maximumTenths)
    let whole = (tenths / 10).clamped(to: range)
    let decimal = tenths % 10
    return (whole, decimal)
}

private func profileImperialHeightParts(fromCentimeters centimeters: Double) -> (feet: Int, inches: Int) {
    let totalInches = Int((centimeters / 2.54).rounded()).clamped(to: 36...107)
    let feet = (totalInches / 12).clamped(to: 3...8)
    let inches = (totalInches - (feet * 12)).clamped(to: 0...11)
    return (feet, inches)
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
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
                            Label {
                                ProfileMenuOptionText(text: label(option))
                            } icon: {
                                Image(systemName: "checkmark")
                            }
                        } else {
                            ProfileMenuOptionText(text: label(option))
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

private struct ProfileMenuOptionText: View {
    let text: String

    private var nonWrappingText: String {
        text
            .replacingOccurrences(of: " ", with: "\u{00A0}")
            .map(String.init)
            .joined(separator: "\u{2060}")
    }

    var body: some View {
        Text(nonWrappingText)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel(text)
    }
}

private struct ProfileMenuValueLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 7) {
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.trailing)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
        }
        .frame(minWidth: 104, minHeight: 38, alignment: .trailing)
    }
}

private struct ProfileSegmentedPicker<Option: Hashable>: View {
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

private struct ProfileGeminiKeyRow: View {
    @Binding var apiKey: String
    let hasSavedKey: Bool
    let save: () -> Void
    let clear: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        ProfileFieldRow(
            title: "Gemini Key",
            systemImage: hasSavedKey ? "checkmark.seal.fill" : "key.fill",
            tint: hasSavedKey ? .deltsAccent : .deltsSecondaryAccent
        ) {
            HStack(spacing: 8) {
                SecureField(hasSavedKey ? "Saved" : "Paste key", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.password)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .frame(minWidth: 112)

                Button(action: save) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Save Gemini key")

                Button(action: clear) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Clear Gemini key")
            }
            .foregroundStyle(Color.deltsMutedText)
        }
    }
}

private struct ProfileMultiSelectMenuRow<Option: Hashable>: View {
    let title: String
    let systemImage: String
    let options: [Option]
    @Binding var selection: Set<Option>
    let label: (Option) -> String

    private var summary: String {
        let selectedTitles = options.filter { selection.contains($0) }.map(label)
        if selectedTitles.isEmpty {
            return "None"
        }
        if selectedTitles.count <= 2 {
            return selectedTitles.joined(separator: ", ")
        }
        return "\(selectedTitles.count) selected"
    }

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        var updatedSelection = selection
                        if updatedSelection.contains(option) {
                            updatedSelection.remove(option)
                        } else {
                            updatedSelection.insert(option)
                        }
                        selection = updatedSelection
                    } label: {
                        if selection.contains(option) {
                            Label(label(option), systemImage: "checkmark")
                        } else {
                            Text(label(option))
                        }
                    }
                }
            } label: {
                ProfileMenuValueLabel(text: summary)
            }
            .deltsPressable()
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
