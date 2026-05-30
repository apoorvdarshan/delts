import Foundation
import SwiftData
import SwiftUI
import UIKit

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
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile
    @AppStorage("profile_measurement_system") private var measurementSystemRaw = MeasurementSystem.metric.rawValue
    @AppStorage("profile_custom_workout_split") private var customWorkoutSplit = ""
    @AppStorage("profile_selected_goals") private var selectedGoalRawValues = ""
    @AppStorage("profile_extra_issues") private var extraIssues = ""
    @AppStorage("profile_dataset_level") private var datasetLevelRaw = ""
    @AppStorage("profile_dataset_primary_muscles") private var datasetPrimaryMusclesRaw = ""
    @AppStorage("profile_dataset_raw_equipment") private var datasetRawEquipmentRaw = ""
    @AppStorage("apple_health_enabled") private var appleHealthEnabled = false
    @AppStorage("profile_goal_weight_kg") private var goalWeightKG = 0.0
    @AppStorage("profile_current_body_fat_is_exact") private var currentBodyFatIsExact = false
    @AppStorage("profile_goal_body_fat_is_exact") private var goalBodyFatIsExact = false
    @State private var isSelectingTargetMuscles = false
    @StateObject private var healthKit = HealthKitProgressService()

    private let exerciseLibraryService = ExerciseLibraryService.shared
    private let sexOptions = ["Male", "Female"]
    private let ageRange = 0...120
    private let frequencyOptions = Array(1...7)
    private let durationRange = 1...300
    private let otherGoalTitle = "Other"
    private var profileGoalOptions: [String] {
        FitnessGoal.profileCases.map(\.title) + [otherGoalTitle]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                identitySection
                goalSection
                scheduleSection
                strengthSection
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
        .background(ProfileKeyboardDismissTapInstaller())
        .fullScreenCover(isPresented: $isSelectingTargetMuscles) {
            ProfileTargetMuscleSelectionSheet(
                selection: datasetPrimaryMusclesBinding,
                allowedValues: exerciseLibraryService.availablePrimaryMuscles,
                gender: profile.gender
            )
        }
    }

    private var identitySection: some View {
        ProfileSection(
            title: "About",
            subtitle: "Basic details used to shape plans.",
            systemImage: "person.text.rectangle"
        ) {
            ProfileRowStack {
                ProfileTextInputRow(title: "Name", systemImage: "person.fill", text: nameBinding, showsKeyboardDone: true)
                ProfileDivider()
                ProfileSexImagePicker(selection: genderBinding)
                ProfileDivider()
                ProfileIntegerPickerRow(
                    title: "Age",
                    systemImage: "calendar",
                    value: ageBinding,
                    range: ageRange,
                    unit: "yr"
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
                ProfileWeightPickerRow(
                    title: "Goal weight",
                    systemImage: "target",
                    system: measurementSystem,
                    kilograms: goalWeightBinding
                )
                ProfileDivider()
                ProfileBodyFatRangePickerRow(
                    title: "Current body fat",
                    systemImage: "percent",
                    value: currentBodyFatBinding,
                    isExact: $currentBodyFatIsExact,
                    sex: profile.gender
                )
                ProfileDivider()
                ProfileBodyFatRangePickerRow(
                    title: "Goal body fat",
                    systemImage: "scope",
                    value: desiredBodyFatBinding,
                    isExact: $goalBodyFatIsExact,
                    sex: profile.gender
                )
                ProfileDivider()
                ProfileFieldRow(title: "Apple Health", systemImage: "heart.text.square") {
                    Toggle("", isOn: appleHealthBinding)
                        .labelsHidden()
                }
            }
        }
    }

    private var appleHealthBinding: Binding<Bool> {
        Binding {
            appleHealthEnabled
        } set: { isEnabled in
            if isEnabled {
                Task { await enableAppleHealth() }
            } else {
                appleHealthEnabled = false
            }
        }
    }

    private var goalSection: some View {
        ProfileSection(
            title: "Goals & Constraints",
            subtitle: "Training targets, focus, and limits before plans are generated.",
            systemImage: "scope"
        ) {
            ProfileRowStack {
                ProfileMenuPicker(
                    title: "Level",
                    systemImage: "chart.line.uptrend.xyaxis",
                    selection: datasetLevelBinding,
                    options: exerciseLibraryService.availableLevels,
                    label: { $0 }
                )
                ProfileDivider()
                ProfileMultiSelectMenuRow(
                    title: "Goals",
                    systemImage: "flag.checkered",
                    options: profileGoalOptions,
                    selection: selectedGoalsBinding,
                    label: { $0 }
                )
                if selectedGoalTitles.contains(otherGoalTitle) {
                    ProfileDivider()
                    ProfileTextAreaRow(title: "Extra goals", systemImage: "text.alignleft", text: extraGoalsBinding)
                }
                ProfileDivider()
                ProfileTargetMuscleSelectorRow(
                    selection: datasetPrimaryMusclesBinding,
                    allowedValues: exerciseLibraryService.availablePrimaryMuscles,
                    isPresented: $isSelectingTargetMuscles
                )
                ProfileDivider()
                ProfileMultiSelectMenuRow(
                    title: "Issues",
                    systemImage: "exclamationmark.triangle.fill",
                    options: FitnessIssue.allCases,
                    selection: issuesBinding,
                    label: { $0.title }
                )
                if profile.fitnessIssues.contains(.other) {
                    ProfileDivider()
                    ProfileTextAreaRow(
                        title: "Extra issues",
                        systemImage: "text.bubble",
                        text: extraIssuesBinding
                    )
                }
            }
        }
    }

    private var scheduleSection: some View {
        ProfileSection(
            title: "Workout Setup",
            subtitle: "Tune how training fits into the week.",
            systemImage: "calendar.badge.clock"
        ) {
            ProfileRowStack {
                ProfileMenuPicker(
                    title: "Frequency",
                    systemImage: "calendar",
                    selection: frequencyBinding,
                    options: frequencyOptions,
                    label: { "\($0) days/week" }
                )
                ProfileDivider()
                ProfileMenuPicker(
                    title: "Workout split",
                    systemImage: "square.split.2x2",
                    selection: splitBinding,
                    options: WorkoutSplit.allCases,
                    label: { $0.title }
                )
                if profile.workoutSplit == .custom {
                    ProfileDivider()
                    ProfileTextInputRow(
                        title: "Custom split",
                        systemImage: "text.line.first.and.arrowtriangle.forward",
                        text: customWorkoutSplitBinding
                    )
                }
                ProfileDivider()
                ProfileIntegerPickerRow(
                    title: "Workout duration",
                    systemImage: "timer",
                    value: durationBinding,
                    range: durationRange,
                    unit: "min"
                )
                ProfileDivider()
                ProfileEquipmentImagePickerRow(
                    title: "Equipment",
                    systemImage: "dumbbell.fill",
                    options: exerciseLibraryService.availableRawEquipment,
                    exercises: exerciseLibraryService.exercises,
                    selection: datasetRawEquipmentBinding,
                    label: { $0 }
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

    private func enableAppleHealth() async {
        do {
            try await healthKit.requestAccess()
            let imported = try await healthKit.importAllSnapshots()
            let current = ProgressMetricStore.load()
            let merged = ProgressMetricStore.merge(imported, into: current)
            if let latestBodyFat = merged.sorted(by: { $0.date < $1.date }).last(where: { $0.bodyFat != nil && $0.bodyFatIsExact == true })?.bodyFat {
                profile.currentBodyFatPercentage = latestBodyFat
                profile.updatedAt = Date()
                currentBodyFatIsExact = true
                try? modelContext.save()
            }
            appleHealthEnabled = true
        } catch {
            appleHealthEnabled = false
        }
    }

    private var genderBinding: Binding<String> {
        Binding {
            sexOptions.contains(profile.gender) ? profile.gender : "Male"
        } set: { newValue in
            if sexOptions.contains(newValue) {
                profile.gender = newValue
                profile.updatedAt = Date()
            }
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

    private var goalWeightBinding: Binding<Double> {
        Binding {
            goalWeightKG > 0 ? goalWeightKG : profile.currentWeightKG
        } set: { newValue in
            goalWeightKG = newValue
        }
    }

    private var currentBodyFatBinding: Binding<Double> {
        doubleBinding(\.currentBodyFatPercentage)
    }

    private var desiredBodyFatBinding: Binding<Double> {
        doubleBinding(\.desiredBodyFatPercentage)
    }

    private var extraGoalsBinding: Binding<String> {
        Binding {
            profile.extraGoals
        } set: { newValue in
            profile.extraGoals = newValue
            profile.updatedAt = Date()
        }
    }

    private var extraIssuesBinding: Binding<String> {
        Binding {
            extraIssues
        } set: { newValue in
            extraIssues = newValue
        }
    }

    private var selectedGoalTitles: Set<String> {
        let storedGoals = Set(
            selectedGoalRawValues
                .split(separator: "|")
                .map(String.init)
                .filter { profileGoalOptions.contains($0) }
        )
        if !storedGoals.isEmpty {
            return storedGoals
        }

        var defaultGoals: Set<String> = [profile.mainGoal.title]
        if !profile.extraGoals.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            defaultGoals.insert(otherGoalTitle)
        }
        return defaultGoals
    }

    private var selectedGoalsBinding: Binding<Set<String>> {
        Binding {
            selectedGoalTitles
        } set: { newValue in
            let normalizedGoals = Set(newValue.filter { profileGoalOptions.contains($0) })
            let nextGoals = normalizedGoals.isEmpty ? Set([profile.mainGoal.title]) : normalizedGoals
            selectedGoalRawValues = nextGoals.sorted().joined(separator: "|")

            if let primaryTitle = profileGoalOptions.first(where: { $0 != otherGoalTitle && nextGoals.contains($0) }),
               let primaryGoal = FitnessGoal(rawValue: primaryTitle) {
                profile.mainGoal = primaryGoal
                profile.updatedAt = Date()
            }
        }
    }

    private var datasetPrimaryMusclesBinding: Binding<Set<String>> {
        Binding {
            let rawSelection = Set(datasetPrimaryMusclesRaw.split(separator: "|").map(String.init))
            return ProfileTargetMuscleGroup.normalized(rawSelection, allowedValues: exerciseLibraryService.availablePrimaryMuscles)
        } set: { newValue in
            let normalizedSelection = ProfileTargetMuscleGroup.normalized(
                newValue,
                allowedValues: exerciseLibraryService.availablePrimaryMuscles
            )
            datasetPrimaryMusclesRaw = datasetStoredString(
                normalizedSelection,
                allowedValues: exerciseLibraryService.availablePrimaryMuscles
            )
        }
    }

    private var datasetLevelBinding: Binding<String> {
        Binding {
            let levels = exerciseLibraryService.availableLevels
            if levels.contains(datasetLevelRaw) {
                return datasetLevelRaw
            }
            if levels.contains(profile.experienceLevelRaw) {
                return profile.experienceLevelRaw
            }
            if profile.experienceLevelRaw == "Advanced", levels.contains("Expert") {
                return "Expert"
            }
            return levels.first ?? "Unspecified"
        } set: { newValue in
            if exerciseLibraryService.availableLevels.contains(newValue) {
                datasetLevelRaw = newValue
            }
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

    private var customWorkoutSplitBinding: Binding<String> {
        Binding {
            customWorkoutSplit
        } set: { newValue in
            customWorkoutSplit = newValue
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

    private var datasetRawEquipmentBinding: Binding<Set<String>> {
        Binding {
            datasetStoredSet(datasetRawEquipmentRaw, allowedValues: exerciseLibraryService.availableRawEquipment)
        } set: { newValue in
            datasetRawEquipmentRaw = datasetStoredString(newValue, allowedValues: exerciseLibraryService.availableRawEquipment)
        }
    }

    private func datasetStoredSet(_ rawValue: String, allowedValues: [String]) -> Set<String> {
        Set(rawValue
            .split(separator: "|")
            .map(String.init)
            .filter { allowedValues.contains($0) })
    }

    private func datasetStoredString(_ values: Set<String>, allowedValues: [String]) -> String {
        values
            .filter { allowedValues.contains($0) }
            .sorted()
            .joined(separator: "|")
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

private struct ProfileKeyboardDismissTapInstaller: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(from: view)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(from: uiView)
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var window: UIWindow?
        private weak var recognizer: UITapGestureRecognizer?

        func installIfNeeded(from view: UIView) {
            guard let window = view.window, self.window !== window else {
                return
            }

            uninstall()

            let recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            window.addGestureRecognizer(recognizer)

            self.window = window
            self.recognizer = recognizer
        }

        func uninstall() {
            if let recognizer, let window {
                window.removeGestureRecognizer(recognizer)
            }
            recognizer = nil
            window = nil
        }

        @objc private func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            !touch.view.isKeyboardTextInput
        }
    }
}

private extension UIView? {
    var isKeyboardTextInput: Bool {
        guard let view = self else {
            return false
        }
        if view is UITextField || view is UITextView {
            return true
        }
        return view.superview.isKeyboardTextInput
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
                    .layoutPriority(2)

                Spacer(minLength: 12)

                content
                    .layoutPriority(0)
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
    var isTechnical = false
    var showsKeyboardDone = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            if showsKeyboardDone {
                ProfileDoneAccessoryTextField(
                    title: title,
                    text: $text,
                    isTechnical: isTechnical,
                    textAlignment: dynamicTypeSize.isAccessibilitySize ? .left : .right
                )
                .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 0 : 120)
                .frame(height: 28)
            } else {
                TextField(title, text: $text)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
                    .foregroundStyle(Color.deltsCharcoal)
                    .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 0 : 120)
                    .textInputAutocapitalization(isTechnical ? .never : .words)
                    .autocorrectionDisabled(isTechnical)
                    .submitLabel(.done)
                    .onSubmit(dismissKeyboard)
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct ProfileDoneAccessoryTextField: UIViewRepresentable {
    let title: String
    @Binding var text: String
    let isTechnical: Bool
    let textAlignment: NSTextAlignment

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.borderStyle = .none
        textField.clearButtonMode = .never
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        textField.inputAccessoryView = context.coordinator.makeAccessoryToolbar()
        applyConfiguration(to: textField, context: context)
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.parent = self
        if textField.text != text {
            textField.text = text
        }
        applyConfiguration(to: textField, context: context)
    }

    private func applyConfiguration(to textField: UITextField, context: Context) {
        textField.placeholder = title
        textField.textAlignment = textAlignment
        textField.textColor = UIColor(Color.deltsCharcoal)
        textField.tintColor = UIColor(Color.deltsAccent)
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.autocapitalizationType = isTechnical ? .none : .words
        textField.autocorrectionType = isTechnical ? .no : .default
        textField.returnKeyType = .done
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ProfileDoneAccessoryTextField

        init(_ parent: ProfileDoneAccessoryTextField) {
            self.parent = parent
        }

        func makeAccessoryToolbar() -> UIToolbar {
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
            let doneItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneTapped))
            doneItem.setTitleTextAttributes(
                [
                    .font: UIFont.boldSystemFont(ofSize: 17),
                    .foregroundColor: UIColor(Color.deltsAccent)
                ],
                for: .normal
            )
            doneItem.setTitleTextAttributes(
                [
                    .font: UIFont.boldSystemFont(ofSize: 17),
                    .foregroundColor: UIColor(Color.deltsAccent).withAlphaComponent(0.45)
                ],
                for: .disabled
            )
            toolbar.items = [
                UIBarButtonItem(systemItem: .flexibleSpace),
                doneItem
            ]
            toolbar.sizeToFit()
            return toolbar
        }

        @objc func textDidChange(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        @objc private func doneTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

private struct ProfileSexImagePicker: View {
    @Binding var selection: String
    @State private var isPickerPresented = false

    private let options: [ProfileSexImageOption] = [
        ProfileSexImageOption(title: "Male", assetName: "bodyfat_male_10_13"),
        ProfileSexImageOption(title: "Female", assetName: "bodyfat_female_18_22")
    ]

    var body: some View {
        ProfileFieldRow(title: "Sex", systemImage: "person.2") {
            Button {
                isPickerPresented = true
            } label: {
                ProfileMenuValueLabel(text: selection)
            }
            .deltsPressable()
            .sheet(isPresented: $isPickerPresented) {
                ProfileSexImagePickerSheet(
                    selection: $selection,
                    options: options
                )
            }
        }
    }
}

private struct ProfileSexImagePickerSheet: View {
    @Binding var selection: String
    let options: [ProfileSexImageOption]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                HStack(spacing: 10) {
                    ForEach(options) { option in
                        Button {
                            selection = option.title
                            dismiss()
                        } label: {
                            ProfileSexImageTile(
                                option: option,
                                isSelected: selection == option.title
                            )
                        }
                        .buttonStyle(.plain)
                        .deltsPressable()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(DeltsBackground())
            .navigationTitle("Sex")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct ProfileSexImageOption: Identifiable {
    var id: String { title }
    let title: String
    let assetName: String
}

private struct ProfileSexImageTile: View {
    let option: ProfileSexImageOption
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(option.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 112)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(Color.deltsAccent)
                        .padding(8)
                        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 2)
                }
            }

            Text(option.title)
                .font(.headline.weight(.heavy))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .fill(isSelected ? Color.deltsAccent.opacity(0.16) : Color.deltsPanel.opacity(0.24))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(isSelected ? Color.deltsAccent.opacity(0.72) : Color.deltsHairline.opacity(0.32), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
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

private struct ProfileIntegerPickerRow: View {
    let title: String
    let systemImage: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    @State private var isPickerPresented = false

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Button {
                isPickerPresented = true
            } label: {
                ProfileMenuValueLabel(text: "\(value.clamped(to: range)) \(unit)")
            }
            .deltsPressable()
            .sheet(isPresented: $isPickerPresented) {
                ProfileIntegerWheelSheet(
                    title: title,
                    initialValue: value,
                    range: range,
                    unit: unit
                ) { newValue in
                    value = newValue
                }
            }
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

private struct ProfileBodyFatRangePickerRow: View {
    let title: String
    let systemImage: String
    @Binding var value: Double
    @Binding var isExact: Bool
    let sex: String
    @State private var isPickerPresented = false

    private var selectedRange: ProfileBodyFatRange {
        ProfileBodyFatRange.matching(value, sex: sex)
    }

    private var valueText: String {
        isExact ? "\(profileFormatDecimal(value))%" : selectedRange.title
    }

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Button {
                isPickerPresented = true
            } label: {
                ProfileMenuValueLabel(text: valueText)
            }
            .deltsPressable()
            .sheet(isPresented: $isPickerPresented) {
                ProfileBodyFatRangeSheet(
                    title: title,
                    selection: $value,
                    isExact: $isExact,
                    sex: sex
                )
            }
        }
    }
}

private struct ProfileBodyFatRangeSheet: View {
    let title: String
    @Binding var selection: Double
    @Binding var isExact: Bool
    let sex: String
    @Environment(\.dismiss) private var dismiss

    private var selectedRange: ProfileBodyFatRange {
        ProfileBodyFatRange.matching(selection, sex: sex)
    }

    private var ranges: [ProfileBodyFatRange] {
        ProfileBodyFatRange.options(for: sex)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ProfileBodyFatExactSetter(initialValue: selection) { exactValue in
                        selection = exactValue
                        isExact = true
                        dismiss()
                    }

                    ForEach(ranges) { range in
                        Button {
                            selection = range.storedValue
                            isExact = false
                            dismiss()
                        } label: {
                            ProfileBodyFatRangeCard(
                                range: range,
                                sex: sex,
                                isSelected: !isExact && range.id == selectedRange.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .background(DeltsBackground())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private struct ProfileBodyFatExactSetter: View {
    let initialValue: Double
    let save: (Double) -> Void

    @State private var whole: Int
    @State private var decimal: Int

    init(initialValue: Double, save: @escaping (Double) -> Void) {
        self.initialValue = initialValue
        self.save = save
        let parts = profileDecimalParts(for: initialValue, range: 0...60)
        _whole = State(initialValue: parts.whole)
        _decimal = State(initialValue: parts.decimal)
    }

    private var selectedValue: Double {
        Double(whole) + (Double(decimal) / 10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label("Exact", systemImage: "number")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.deltsCharcoal)

                Spacer()

                Text("\(profileFormatDecimal(selectedValue))%")
                    .font(.title3.monospacedDigit().weight(.heavy))
                    .foregroundStyle(Color.deltsAccent)
            }

            HStack(spacing: 10) {
                ProfileWheelColumn(title: "Whole", selection: $whole, values: Array(0...60)) { "\($0)" }
                ProfileWheelColumn(title: "Decimal", selection: $decimal, values: Array(0...9)) { ".\($0)" }
            }
            .frame(height: 138)

            PrimaryButton(title: "Set exact", systemImage: "checkmark") {
                save(selectedValue)
            }
        }
        .padding(12)
        .background(Color.deltsPanel.opacity(0.22), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.deltsAccent.opacity(0.28), lineWidth: 1)
        }
    }
}

private struct ProfileBodyFatRangeCard: View {
    let range: ProfileBodyFatRange
    let sex: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Image(range.assetName(for: sex))
                    .resizable()
                    .scaledToFill()
                    .frame(height: 158)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.deltsAccent)
                        .padding(10)
                        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 2)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(range.title)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Color.deltsCharcoal)

                Text(range.summary)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isSelected ? Color.deltsAccent.opacity(0.18) : Color.deltsPanel.opacity(0.74))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.deltsAccent.opacity(0.72) : Color.deltsMutedText.opacity(0.12), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(range.title), \(range.summary)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

private struct ProfileBodyFatRange: Identifiable {
    let id: String
    let title: String
    let lowerBound: Double
    let upperBound: Double?
    let storedValue: Double
    let summary: String

    private static let maleRanges: [ProfileBodyFatRange] = [
        ProfileBodyFatRange(id: "06_09", title: "6-9%", lowerBound: 6, upperBound: 9, storedValue: 8, summary: "Very lean"),
        ProfileBodyFatRange(id: "10_13", title: "10-13%", lowerBound: 10, upperBound: 13, storedValue: 12, summary: "Lean"),
        ProfileBodyFatRange(id: "14_17", title: "14-17%", lowerBound: 14, upperBound: 17, storedValue: 16, summary: "Fit"),
        ProfileBodyFatRange(id: "18_22", title: "18-22%", lowerBound: 18, upperBound: 22, storedValue: 20, summary: "Average"),
        ProfileBodyFatRange(id: "23_27", title: "23-27%", lowerBound: 23, upperBound: 27, storedValue: 25, summary: "Soft"),
        ProfileBodyFatRange(id: "28_32", title: "28-32%", lowerBound: 28, upperBound: 32, storedValue: 30, summary: "Fuller"),
        ProfileBodyFatRange(id: "33_plus", title: "33%+", lowerBound: 33, upperBound: nil, storedValue: 36, summary: "High")
    ]

    private static let femaleRanges: [ProfileBodyFatRange] = [
        ProfileBodyFatRange(id: "06_09", title: "6-9%", lowerBound: 6, upperBound: 9, storedValue: 8, summary: "Very lean"),
        ProfileBodyFatRange(id: "10_13", title: "10-13%", lowerBound: 10, upperBound: 13, storedValue: 12, summary: "Lean"),
        ProfileBodyFatRange(id: "14_17", title: "14-17%", lowerBound: 14, upperBound: 17, storedValue: 16, summary: "Fit"),
        ProfileBodyFatRange(id: "18_22", title: "18-22%", lowerBound: 18, upperBound: 22, storedValue: 20, summary: "Average"),
        ProfileBodyFatRange(id: "23_27", title: "23-27%", lowerBound: 23, upperBound: 27, storedValue: 25, summary: "Soft"),
        ProfileBodyFatRange(id: "28_32", title: "28-32%", lowerBound: 28, upperBound: 32, storedValue: 30, summary: "Fuller"),
        ProfileBodyFatRange(id: "33_plus", title: "33%+", lowerBound: 33, upperBound: nil, storedValue: 36, summary: "High")
    ]

    static func options(for sex: String) -> [ProfileBodyFatRange] {
        sex.localizedCaseInsensitiveContains("female") ? femaleRanges : maleRanges
    }

    static func matching(_ value: Double, sex: String) -> ProfileBodyFatRange {
        let ranges = options(for: sex)
        let roundedValue = value.rounded()
        if let exactRange = ranges.first(where: { range in
            guard roundedValue >= range.lowerBound else {
                return false
            }
            return roundedValue <= (range.upperBound ?? .greatestFiniteMagnitude)
        }) {
            return exactRange
        }
        return roundedValue < (ranges.first?.lowerBound ?? 0) ? ranges[0] : ranges[ranges.count - 1]
    }

    func assetName(for sex: String) -> String {
        let normalizedSex = sex.localizedCaseInsensitiveContains("female") ? "female" : "male"
        return "bodyfat_\(normalizedSex)_\(id)"
    }
}

private struct ProfileIntegerWheelSheet: View {
    let title: String
    let unit: String
    let options: [Int]
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedValue: Int

    init(
        title: String,
        initialValue: Int,
        range: ClosedRange<Int>,
        unit: String,
        onSave: @escaping (Int) -> Void
    ) {
        self.title = title
        self.unit = unit
        self.options = Array(range)
        self.onSave = onSave
        _selectedValue = State(initialValue: initialValue.clamped(to: range))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(selectedValue) \(unit)")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .frame(maxWidth: .infinity, alignment: .center)

                ProfileWheelColumn(title: title, selection: $selectedValue, values: options) { "\($0)" }
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
        .presentationDetents([.height(320), .medium])
        .presentationDragIndicator(.visible)
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
        .frame(minWidth: 72, maxWidth: 178, minHeight: 38, alignment: .trailing)
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

private struct ProfileToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
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

private struct ProfileEquipmentImagePickerRow: View {
    let title: String
    let systemImage: String
    let options: [String]
    let exercises: [ExerciseLibraryItem]
    @Binding var selection: Set<String>
    let label: (String) -> String
    @State private var isPickerPresented = false

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

    private var imageOptions: [ProfileEquipmentImageOption] {
        options.map { option in
            let matchingExercises = exercises.filter { $0.rawEquipment == option }
            let representative = matchingExercises.first { !$0.imagePaths.isEmpty && $0.category != "Stretching" }
                ?? matchingExercises.first { !$0.imagePaths.isEmpty }

            return ProfileEquipmentImageOption(
                value: option,
                title: label(option),
                count: matchingExercises.count,
                imagePaths: representative?.imagePaths ?? []
            )
        }
    }

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Button {
                isPickerPresented = true
            } label: {
                ProfileMenuValueLabel(text: summary)
            }
            .deltsPressable()
            .sheet(isPresented: $isPickerPresented) {
                ProfileEquipmentImagePickerSheet(
                    title: title,
                    options: imageOptions,
                    selection: $selection
                )
            }
        }
    }
}

private struct ProfileEquipmentImageOption: Identifiable {
    var id: String { value }
    let value: String
    let title: String
    let count: Int
    let imagePaths: [String]
}

private struct ProfileEquipmentImagePickerSheet: View {
    let title: String
    let options: [ProfileEquipmentImageOption]
    @Binding var selection: Set<String>
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(options) { option in
                        Button {
                            toggle(option.value)
                        } label: {
                            ProfileEquipmentImageTile(
                                option: option,
                                isSelected: selection.contains(option.value)
                            )
                        }
                        .buttonStyle(.plain)
                        .deltsPressable()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(DeltsBackground())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func toggle(_ value: String) {
        var updatedSelection = selection
        if updatedSelection.contains(value) {
            updatedSelection.remove(value)
        } else {
            updatedSelection.insert(value)
        }
        selection = updatedSelection
    }
}

private struct ProfileEquipmentImageTile: View {
    let option: ProfileEquipmentImageOption
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AnimatedExerciseVisual(
                    imagePaths: option.imagePaths,
                    height: 116,
                    allowsDerivedImageLookup: false,
                    fallbackSystemImage: "dumbbell.fill",
                    fallbackTitle: option.title
                )

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(Color.deltsAccent)
                        .padding(8)
                        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 2)
                }
            }

            Text(option.title)
                .font(.headline.weight(.heavy))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            Text("\(option.count) exercises")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .fill(isSelected ? Color.deltsAccent.opacity(0.16) : Color.deltsPanel.opacity(0.24))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(isSelected ? Color.deltsAccent.opacity(0.72) : Color.deltsHairline.opacity(0.32), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(option.title), \(option.count) exercises")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

private struct ProfileTargetMuscleGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let muscles: [String]
    let isComposite: Bool

    var muscleSet: Set<String> {
        Set(muscles)
    }

    func availableMuscles(allowedValues: [String]) -> [String] {
        muscles.filter { allowedValues.contains($0) }
    }

    func imageName(gender: String) -> String {
        let prefix = gender == "Female" ? "target_female" : "target_male"
        return "\(prefix)_\(id)"
    }

    nonisolated static let all: [ProfileTargetMuscleGroup] = [
        ProfileTargetMuscleGroup(
            id: "chest",
            title: "Chest",
            detail: "Pecs",
            systemImage: "figure.strengthtraining.traditional",
            muscles: ["Chest"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "shoulders",
            title: "Shoulders",
            detail: "Delts",
            systemImage: "figure.strengthtraining.functional",
            muscles: ["Shoulders"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "abdominals",
            title: "Abdominals",
            detail: "Abdominals",
            systemImage: "figure.core.training",
            muscles: ["Abdominals"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "biceps",
            title: "Biceps",
            detail: "Front upper arm",
            systemImage: "dumbbell.fill",
            muscles: ["Biceps"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "triceps",
            title: "Triceps",
            detail: "Back upper arm",
            systemImage: "dumbbell.fill",
            muscles: ["Triceps"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "forearms",
            title: "Forearms",
            detail: "Grip and lower arm",
            systemImage: "dumbbell.fill",
            muscles: ["Forearms"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "lats",
            title: "Lats",
            detail: "Width-focused back",
            systemImage: "figure.pullup",
            muscles: ["Lats"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "middle_back",
            title: "Middle Back",
            detail: "Rows and upper-back thickness",
            systemImage: "figure.pullup",
            muscles: ["Middle Back"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "lower_back",
            title: "Lower Back",
            detail: "Spinal erectors",
            systemImage: "figure.flexibility",
            muscles: ["Lower Back"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "traps",
            title: "Traps",
            detail: "Upper back and neck line",
            systemImage: "figure.strengthtraining.functional",
            muscles: ["Traps"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "quadriceps",
            title: "Quadriceps",
            detail: "Quadriceps",
            systemImage: "figure.run",
            muscles: ["Quadriceps"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "hamstrings",
            title: "Hamstrings",
            detail: "Posterior thigh",
            systemImage: "figure.run",
            muscles: ["Hamstrings"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "glutes",
            title: "Glutes",
            detail: "Hips and glutes",
            systemImage: "figure.run",
            muscles: ["Glutes"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "calves",
            title: "Calves",
            detail: "Lower leg",
            systemImage: "figure.run",
            muscles: ["Calves"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "abductors",
            title: "Abductors",
            detail: "Outer hip",
            systemImage: "figure.walk",
            muscles: ["Abductors"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "adductors",
            title: "Adductors",
            detail: "Inner thigh",
            systemImage: "figure.walk",
            muscles: ["Adductors"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "neck",
            title: "Neck",
            detail: "Neck",
            systemImage: "figure.stand",
            muscles: ["Neck"],
            isComposite: false
        )
    ]

    static func groups(allowedValues: [String]) -> [ProfileTargetMuscleGroup] {
        all.filter { !$0.availableMuscles(allowedValues: allowedValues).isEmpty }
    }

    nonisolated static func group(id: String) -> ProfileTargetMuscleGroup? {
        all.first { $0.id == id }
    }

    static func normalized(_ values: Set<String>, allowedValues: [String]) -> Set<String> {
        let allowedSet = Set(allowedValues)
        var normalizedValues = Set<String>()

        for value in values {
            if allowedSet.contains(value) {
                normalizedValues.insert(value)
                continue
            }

            if let group = all.first(where: {
                $0.title.caseInsensitiveCompare(value) == .orderedSame ||
                $0.id.caseInsensitiveCompare(value) == .orderedSame
            }) {
                normalizedValues.formUnion(group.availableMuscles(allowedValues: allowedValues))
                continue
            }

            if let legacyMuscles = legacyAliases[value.lowercased()] {
                normalizedValues.formUnion(legacyMuscles.filter { allowedSet.contains($0) })
            }
        }

        return normalizedValues
    }

    nonisolated private static let legacyAliases: [String: [String]] = [
        "core": ["Abdominals"],
        "abs / core": ["Abdominals"],
        "quads": ["Quadriceps"],
        "hips": ["Abductors", "Adductors"],
        "arms": ["Biceps", "Triceps", "Forearms"],
        "back": ["Lats", "Middle Back", "Lower Back", "Traps"],
        "legs": ["Quadriceps", "Hamstrings", "Glutes", "Calves", "Abductors", "Adductors"]
    ]

    static func toggled(
        selection: Set<String>,
        group: ProfileTargetMuscleGroup,
        allowedValues: [String]
    ) -> Set<String> {
        let normalizedSelection = normalized(selection, allowedValues: allowedValues)
        let groupMuscles = Set(group.availableMuscles(allowedValues: allowedValues))
        guard !groupMuscles.isEmpty else { return normalizedSelection }

        if groupMuscles.isSubset(of: normalizedSelection) {
            let protectedMuscles = Set(groups(allowedValues: allowedValues)
                .filter { $0.id != group.id }
                .filter { Set($0.availableMuscles(allowedValues: allowedValues)).isSubset(of: normalizedSelection) }
                .flatMap { $0.availableMuscles(allowedValues: allowedValues) })

            return normalizedSelection.subtracting(groupMuscles.subtracting(protectedMuscles))
        }

        return normalizedSelection.union(groupMuscles)
    }

    static func selectedGroups(selection: Set<String>, allowedValues: [String]) -> [ProfileTargetMuscleGroup] {
        let normalizedSelection = normalized(selection, allowedValues: allowedValues)
        guard !normalizedSelection.isEmpty else { return [] }

        let availableGroups = groups(allowedValues: allowedValues)
        let fullySelected = availableGroups.filter {
            Set($0.availableMuscles(allowedValues: allowedValues)).isSubset(of: normalizedSelection)
        }
        let compositeCoverage = Set(fullySelected
            .filter(\.isComposite)
            .flatMap { $0.availableMuscles(allowedValues: allowedValues) })

        return fullySelected.filter { group in
            if group.isComposite {
                return true
            }
            return !Set(group.availableMuscles(allowedValues: allowedValues)).isSubset(of: compositeCoverage)
        }
    }

    static func summary(selection: Set<String>, allowedValues: [String]) -> String {
        let titles = selectedGroups(selection: selection, allowedValues: allowedValues).map(\.title)
        if titles.isEmpty {
            return "None"
        }
        if titles.count <= 2 {
            return titles.joined(separator: ", ")
        }
        return "\(titles.count) selected"
    }
}

private struct ProfileTargetMuscleSection: Identifiable {
    let id: String
    let title: String
    let detail: String
    let groupIDs: [String]

    func groups(allowedValues: [String]) -> [ProfileTargetMuscleGroup] {
        groupIDs
            .compactMap(ProfileTargetMuscleGroup.group(id:))
            .filter { !$0.availableMuscles(allowedValues: allowedValues).isEmpty }
    }

    static let all: [ProfileTargetMuscleSection] = [
        ProfileTargetMuscleSection(
            id: "upper",
            title: "Upper Body",
            detail: "Chest and shoulders.",
            groupIDs: ["chest", "shoulders"]
        ),
        ProfileTargetMuscleSection(
            id: "back",
            title: "Back",
            detail: "Choose the exact back area.",
            groupIDs: ["lats", "middle_back", "lower_back", "traps"]
        ),
        ProfileTargetMuscleSection(
            id: "arms",
            title: "Arms",
            detail: "Biceps, triceps, and forearms are separate.",
            groupIDs: ["biceps", "triceps", "forearms"]
        ),
        ProfileTargetMuscleSection(
            id: "core",
            title: "Core",
            detail: "Abdominal work.",
            groupIDs: ["abdominals"]
        ),
        ProfileTargetMuscleSection(
            id: "legs",
            title: "Legs / Hips",
            detail: "Every primary lower-body target stays separate.",
            groupIDs: ["quadriceps", "hamstrings", "glutes", "calves", "abductors", "adductors"]
        ),
        ProfileTargetMuscleSection(
            id: "neck",
            title: "Neck",
            detail: "Optional neck focus.",
            groupIDs: ["neck"]
        )
    ]

    static func sections(allowedValues: [String]) -> [ProfileTargetMuscleSection] {
        all.filter { !$0.groups(allowedValues: allowedValues).isEmpty }
    }
}

private struct ProfileTargetMuscleSelectorRow: View {
    @Binding var selection: Set<String>
    let allowedValues: [String]
    @Binding var isPresented: Bool

    private var selectedGroups: [ProfileTargetMuscleGroup] {
        ProfileTargetMuscleGroup.selectedGroups(selection: selection, allowedValues: allowedValues)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                isPresented = true
            } label: {
                ProfileFieldRow(title: "Target muscles", systemImage: "scope") {
                    ProfileMenuValueLabel(
                        text: ProfileTargetMuscleGroup.summary(
                            selection: selection,
                            allowedValues: allowedValues
                        )
                    )
                }
            }
            .buttonStyle(.plain)
            .deltsPressable()

            if !selectedGroups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedGroups) { group in
                            ProfileTargetMuscleChip(title: group.title)
                        }
                    }
                    .padding(.leading, 48)
                    .padding(.trailing, 6)
                    .padding(.bottom, 10)
                }
            }
        }
    }
}

private struct ProfileTargetMuscleChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.deltsAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.deltsAccent.opacity(0.12), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.deltsAccent.opacity(0.22), lineWidth: 0.5)
            }
    }
}

private struct ProfileTargetMuscleSelectionSheet: View {
    @Binding var selection: Set<String>
    let allowedValues: [String]
    let gender: String
    @Environment(\.dismiss) private var dismiss

    private var sections: [ProfileTargetMuscleSection] {
        ProfileTargetMuscleSection.sections(allowedValues: allowedValues)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TARGET MUSCLES")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Color.deltsAccent)

                        Text("Pick body parts")
                            .font(.title.weight(.heavy))
                            .foregroundStyle(Color.deltsCharcoal)
                    }

                    ForEach(sections) { section in
                        let sectionGroups = section.groups(allowedValues: allowedValues)
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.title)
                                .font(.title2.weight(.heavy))
                                .foregroundStyle(Color.deltsCharcoal)

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)
                                ],
                                alignment: .leading,
                                spacing: 10
                            ) {
                                ForEach(sectionGroups) { group in
                                    let groupMuscles = Set(group.availableMuscles(allowedValues: allowedValues))
                                    ProfileTargetMuscleCard(
                                        group: group,
                                        gender: gender,
                                        isSelected: groupMuscles.isSubset(of: selection),
                                        toggle: {
                                            selection = ProfileTargetMuscleGroup.toggled(
                                                selection: selection,
                                                group: group,
                                                allowedValues: allowedValues
                                            )
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color.deltsBackground.ignoresSafeArea())
            .navigationTitle("Target muscles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.bold))
                }
            }
        }
    }
}

private struct ProfileTargetMuscleCard: View {
    let group: ProfileTargetMuscleGroup
    let gender: String
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    ProfileTargetMuscleAssetImage(
                        imageName: group.imageName(gender: gender)
                    )
                    .frame(height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 25, weight: .bold))
                            .foregroundStyle(Color.deltsAccent)
                            .padding(8)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.title)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.deltsCharcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)

                    Text(group.detail)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }

                Spacer(minLength: 0)

                Label(isSelected ? "Selected" : "Select", systemImage: isSelected ? "checkmark" : "plus")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(isSelected ? Color.deltsAccent.opacity(0.13) : Color.deltsAccent, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(isSelected ? Color.deltsAccent.opacity(0.34) : Color.clear, lineWidth: 0.5)
                    }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 198, alignment: .topLeading)
            .background(Color.deltsPanel.opacity(isSelected ? 0.34 : 0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.deltsAccent.opacity(0.62) : Color.deltsHairline.opacity(0.24), lineWidth: isSelected ? 1.5 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ProfileTargetMuscleAssetImage: View {
    let imageName: String

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.deltsPanel.opacity(0.42))

            Image(imageName)
                .resizable()
                .scaledToFill()
                .overlay {
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.42)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
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
