import Foundation
import SwiftData
import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @ObservedObject var updateChecker: AppUpdateChecker

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first {
                    ProfileEditorView(profile: profile, updateChecker: updateChecker)
                } else {
                    ProfileLoadingView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                try? modelContext.save()
            }
        }
    }
}

enum ProfileSectionKind: CaseIterable {
    case libraryFilters
    case appPreferences
    case about
}

struct ProfileEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: UserProfile
    var updateChecker: AppUpdateChecker?
    var sections: Set<ProfileSectionKind> = Set(ProfileSectionKind.allCases)
    var embedded: Bool = false
    @AppStorage("profile_dataset_primary_muscles") private var datasetPrimaryMusclesRaw = ""
    @AppStorage("profile_dataset_raw_equipment") private var datasetRawEquipmentRaw = ""
    @AppStorage("profile_show_only_target_primary_filters") private var showOnlyTargetPrimaryFilters = false
    @AppStorage(AppAppearance.storageKey) private var appAppearanceRaw = AppAppearance.system.rawValue
    @AppStorage(DeltsTheme.storageKey) private var deltsThemeRaw = DeltsTheme.lime.rawValue
    @State private var isSelectingTargetMuscles = false
    @State private var isTargetOnlyPrimaryInfoPresented = false

    private let exerciseLibraryService = ExerciseLibraryService.shared

    var body: some View {
        Group {
            if embedded {
                sectionStack
            } else {
                ScrollView {
                    sectionStack
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
        }
        .background(ProfileKeyboardDismissTapInstaller())
        .fullScreenCover(isPresented: $isSelectingTargetMuscles) {
            ProfileTargetMuscleSelectionSheet(
                selection: datasetPrimaryMusclesBinding,
                allowedValues: exerciseLibraryService.availablePrimaryMuscles,
                gender: profile.gender
            )
        }
        .alert("Target-only Primary", isPresented: $isTargetOnlyPrimaryInfoPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("When enabled, exercise filters only show moves whose primary target matches your selected target muscles.")
        }
    }

    @ViewBuilder
    private var sectionStack: some View {
        VStack(alignment: .leading, spacing: 18) {
            if sections.contains(.libraryFilters) { libraryFiltersSection }
            if sections.contains(.appPreferences) { appPreferencesSection }
            if sections.contains(.about), let updateChecker {
                AboutSettingsSection(updateChecker: updateChecker)
            }
        }
    }

    private var libraryFiltersSection: some View {
        ProfileSection(
            title: String(localized: "Library Filters"),
            subtitle: String(localized: "Tailor the exercise library to your training."),
            systemImage: "line.3.horizontal.decrease"
        ) {
            ProfileRowStack {
                ProfileWorkoutSplitPickerRow(
                    title: String(localized: "Workout split"),
                    systemImage: "square.split.2x2",
                    selection: splitBinding
                )
                ProfileDivider()
                ProfileEquipmentImagePickerRow(
                    title: String(localized: "Equipment"),
                    systemImage: "dumbbell.fill",
                    options: exerciseLibraryService.availableRawEquipment,
                    exercises: exerciseLibraryService.exercises,
                    selection: datasetRawEquipmentBinding,
                    label: { $0 }
                )
                ProfileDivider()
                ProfileTargetMuscleSelectorRow(
                    selection: datasetPrimaryMusclesBinding,
                    allowedValues: exerciseLibraryService.availablePrimaryMuscles,
                    isPresented: $isSelectingTargetMuscles
                )
                ProfileDivider()
                ProfileToggleInfoRow(
                    title: String(localized: "Target-only Primary"),
                    systemImage: "scope",
                    isOn: $showOnlyTargetPrimaryFilters
                ) {
                    isTargetOnlyPrimaryInfoPresented = true
                }
            }
        }
    }

    private var appPreferencesSection: some View {
        ProfileSection(
            title: String(localized: "App Preferences"),
            subtitle: String(localized: "Display options for Delts."),
            systemImage: "gearshape.fill"
        ) {
            ProfileRowStack {
                ProfileThemePickerRow(selection: deltsThemeBinding)
                ProfileDivider()
                ProfileMenuPicker(
                    title: String(localized: "Appearance"),
                    systemImage: "circle.lefthalf.filled",
                    selection: appAppearanceBinding,
                    options: AppAppearance.allCases,
                    label: { $0.title }
                )
            }
        }
    }

    private var appAppearanceBinding: Binding<AppAppearance> {
        Binding {
            AppAppearance(rawValue: appAppearanceRaw) ?? .system
        } set: { newValue in
            appAppearanceRaw = newValue.rawValue
        }
    }

    private var deltsThemeBinding: Binding<DeltsTheme> {
        Binding {
            DeltsTheme(rawValue: deltsThemeRaw) ?? .lime
        } set: { newValue in
            deltsThemeRaw = newValue.rawValue
            DeltsTheme.applyAppIcon(for: newValue)
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
    var assetImageName: String? = nil
    var tint: Color = .deltsSecondaryAccent

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            if let assetImageName {
                Image(assetImageName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(tint)
                    .frame(width: 27, height: 27)
                    .frame(width: 38, height: 34)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 34)
            }

            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
    }
}

private struct ProfileFieldRow<Content: View>: View {
    let title: String
    let systemImage: String
    let assetImageName: String?
    let tint: Color
    let content: Content
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        title: String,
        systemImage: String,
        assetImageName: String? = nil,
        tint: Color = .deltsSecondaryAccent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.assetImageName = assetImageName
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                ProfileFieldLabel(title: title, systemImage: systemImage, assetImageName: assetImageName, tint: tint)
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        } else {
            HStack(alignment: .center, spacing: 12) {
                ProfileFieldLabel(title: title, systemImage: systemImage, assetImageName: assetImageName, tint: tint)
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

private struct ProfileThemePickerRow: View {
    @Binding var selection: DeltsTheme

    private var columns: [GridItem] {
        DeltsTheme.allCases.map { _ in GridItem(.flexible(), spacing: 8) }
    }

    var body: some View {
        ProfileControlBlock(title: String(localized: "Theme"), systemImage: "paintpalette.fill") {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(DeltsTheme.allCases) { theme in
                    Button {
                        withAnimation(.easeOut(duration: 0.16)) {
                            selection = theme
                        }
                    } label: {
                        ProfileThemeOptionTile(
                            theme: theme,
                            isSelected: selection == theme
                        )
                    }
                    .buttonStyle(.plain)
                    .deltsPressable()
                }
            }
        }
    }
}

private struct ProfileThemeOptionTile: View {
    let theme: DeltsTheme
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 7) {
            ZStack(alignment: .topTrailing) {
                DeltsThemeIconPreview(theme: theme)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(theme.previewColor)
                        .background(Color.black.opacity(0.86), in: Circle())
                        .offset(x: 4, y: -4)
                }
            }

            Text(theme.title)
                .font(.caption2.weight(.heavy))
                .foregroundStyle(isSelected ? Color.deltsCharcoal : Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, minHeight: 82)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? theme.previewColor.opacity(0.16) : Color.deltsPanel.opacity(0.20))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? theme.previewColor.opacity(0.78) : Color.deltsHairline.opacity(0.26), lineWidth: isSelected ? 1.2 : 0.6)
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(theme.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

private struct DeltsThemeIconPreview: View {
    let theme: DeltsTheme

    var body: some View {
        Image(theme.previewAssetName)
            .resizable()
            .scaledToFill()
            .frame(width: 42, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 0.6)
            }
    }
}

private struct ProfileToggleInfoRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool
    let onInfo: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                fixedLabel
                controls
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        } else {
            HStack(alignment: .center, spacing: 8) {
                fixedLabel
                    .layoutPriority(3)

                Spacer(minLength: 6)

                controls
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
    }

    private var fixedLabel: some View {
        HStack(alignment: .center, spacing: 11) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.deltsSecondaryAccent)
                .frame(width: 38, height: 34)

            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var controls: some View {
        HStack(spacing: 6) {
            Button(action: onInfo) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.deltsSecondaryAccent)
                    .frame(width: 30, height: 30)
                    .background(Color.deltsPanel.opacity(0.28), in: Circle())
            }
            .buttonStyle(.plain)
            .deltsPressable()
            .accessibilityLabel("Explain \(title)")

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .fixedSize()
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
        if selectedTitles.isEmpty {
            return String(localized: "None")
        }
        if selectedTitles.count <= 2 {
            return selectedTitles.joined(separator: ", ")
        }
        return String(localized: "\(selectedTitles.count) selected")
    }

    private var selectedTitles: [String] {
        options.filter { selection.contains($0) }.map(label)
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
        VStack(alignment: .leading, spacing: 0) {
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

            if !selectedTitles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedTitles, id: \.self) { title in
                            ProfileTargetMuscleChip(title: title)
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

private struct ProfileWorkoutSplitPickerRow: View {
    let title: String
    let systemImage: String
    @Binding var selection: WorkoutSplit
    @State private var isPickerPresented = false

    var body: some View {
        ProfileFieldRow(title: title, systemImage: systemImage) {
            Button {
                isPickerPresented = true
            } label: {
                ProfileMenuValueLabel(text: selection.title)
            }
            .deltsPressable()
            .sheet(isPresented: $isPickerPresented) {
                ProfileWorkoutSplitPickerSheet(selection: $selection)
            }
        }
    }
}

private struct ProfileWorkoutSplitPickerSheet: View {
    @Binding var selection: WorkoutSplit
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(WorkoutSplit.allCases) { split in
                            Button {
                                selection = split
                            } label: {
                                ProfileWorkoutSplitChoiceRow(
                                    split: split,
                                    isSelected: split == selection
                                )
                            }
                            .id(split.id)
                            .buttonStyle(.plain)
                            .deltsPressable()
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(selection.id, anchor: .center)
                    }
                }
            }
            .background(DeltsBackground())
            .navigationTitle("Workout split")
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

private struct ProfileWorkoutSplitChoiceRow: View {
    let split: WorkoutSplit
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            ProfileWorkoutSplitVisual(split: split, isSelected: isSelected)

            VStack(alignment: .leading, spacing: 6) {
                Text(split.title)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(split.profileDescription)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.deltsAccent)
                    .frame(width: 25, height: 25)
            } else {
                Color.clear
                    .frame(width: 25, height: 25)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isSelected ? Color.deltsAccent.opacity(0.16) : Color.deltsPanel.opacity(0.20))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.deltsAccent.opacity(0.74) : Color.deltsHairline.opacity(0.28), lineWidth: isSelected ? 1.3 : 0.7)
        }
    }
}

private struct ProfileWorkoutSplitVisual: View {
    let split: WorkoutSplit
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.deltsPanel.opacity(isSelected ? 0.52 : 0.32))

            if let assetImage = UIImage(named: split.profileAssetName) {
                Image(uiImage: assetImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 148, height: 148)
                    .clipped()
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.08),
                                Color.black.opacity(0.34)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } else {
                fallbackVisual
            }
        }
        .frame(width: 148, height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.7)
        }
    }

    private var fallbackVisual: some View {
        VStack(spacing: 7) {
            HStack(spacing: 5) {
                ForEach(Array(split.profilePattern.enumerated()), id: \.offset) { _, symbol in
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .heavy))
                }
            }
            .foregroundStyle(isSelected ? Color.deltsOnAccent.opacity(0.78) : Color.deltsSecondaryAccent.opacity(0.72))

            Image(systemName: split.profileSystemImage)
                .font(.system(size: 50, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isSelected ? Color.deltsOnAccent : Color.deltsSecondaryAccent)
        }
    }

}

private extension WorkoutSplit {
    var profileAssetName: String {
        switch self {
        case .fullBody: return "workout_split_full_body"
        case .upperLower: return "workout_split_upper_lower"
        case .pushPullLegs: return "workout_split_push_pull_legs"
        case .broSplit: return "workout_split_bro_split"
        case .arnoldSplit: return "workout_split_arnold_split"
        case .pushPull: return "workout_split_push_pull"
        case .antagonistSplit: return "workout_split_antagonist_split"
        case .hybridSplit: return "workout_split_hybrid_split"
        case .custom: return "workout_split_custom"
        }
    }

    var profileSystemImage: String {
        switch self {
        case .fullBody: return "figure.strengthtraining.traditional"
        case .upperLower: return "square.split.2x1"
        case .pushPullLegs: return "arrow.triangle.branch"
        case .broSplit: return "person.3.fill"
        case .arnoldSplit: return "figure.arms.open"
        case .pushPull: return "arrow.left.arrow.right"
        case .antagonistSplit: return "circle.grid.cross"
        case .hybridSplit: return "sparkles"
        case .custom: return "pencil"
        }
    }

    var profilePattern: [String] {
        switch self {
        case .fullBody:
            return ["circle.fill", "circle.fill", "circle.fill"]
        case .upperLower:
            return ["rectangle.tophalf.filled", "rectangle.bottomhalf.filled"]
        case .pushPullLegs:
            return ["arrow.up.forward", "arrow.down.backward", "figure.run"]
        case .broSplit:
            return ["1.circle.fill", "2.circle.fill", "3.circle.fill"]
        case .arnoldSplit:
            return ["figure.arms.open", "dumbbell.fill", "figure.run"]
        case .pushPull:
            return ["arrow.left", "arrow.right"]
        case .antagonistSplit:
            return ["arrow.left.and.right.circle.fill", "circle.grid.cross"]
        case .hybridSplit:
            return ["sparkle", "dumbbell.fill", "plus"]
        case .custom:
            return ["pencil", "text.line.first.and.arrowtriangle.forward"]
        }
    }

    var profileDescription: String {
        switch self {
        case .fullBody:
            return String(localized: "Train the whole body each workout with broad coverage.")
        case .upperLower:
            return String(localized: "Alternate upper-body, lower-body, and core-focused days.")
        case .pushPullLegs:
            return String(localized: "Group exercises into push, pull, legs, and core work.")
        case .broSplit:
            return String(localized: "Focus each day around one major muscle or body region.")
        case .arnoldSplit:
            return String(localized: "Pair chest/back, shoulders/arms, legs, and core days.")
        case .pushPull:
            return String(localized: "Split work by pushing and pulling patterns across the body.")
        case .antagonistSplit:
            return String(localized: "Pair opposing muscle groups for balanced sessions.")
        case .hybridSplit:
            return String(localized: "Mix compound strength days with accessory hypertrophy work.")
        case .custom:
            return String(localized: "Use your own split text for plan prompts and filtering.")
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
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ProfileSelectionActionRow(
                        selectAllDisabled: selectableValues.isEmpty || selectableValues.isSubset(of: selection),
                        clearAllDisabled: selection.isEmpty,
                        selectAll: {
                            selection = selectableValues
                        },
                        clearAll: {
                            selection.removeAll()
                        }
                    )

                    LazyVGrid(columns: columns, spacing: 18) {
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
                }
                .padding(.horizontal, 18)
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

    private var selectableValues: Set<String> {
        Set(options.map(\.value))
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
                equipmentVisual

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.deltsAccent)
                        .shadow(color: Color.deltsCharcoal.opacity(0.28), radius: 6, y: 2)
                        .padding(7)
                }
            }

            Text(option.title)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(2)
                .minimumScaleFactor(0.70)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()

            Text("\(option.count) exercises")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()
        }
        .padding(7)
        .frame(maxWidth: .infinity, minHeight: 172, alignment: .topLeading)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? Color.deltsAccent.opacity(0.16) : Color.deltsPanel.opacity(0.24))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.deltsAccent.opacity(0.72) : Color.deltsHairline.opacity(0.32), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(option.title), \(option.count) exercises")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    private var equipmentVisual: some View {
        AnimatedExerciseVisual(
            imagePaths: option.imagePaths,
            height: 96,
            allowsDerivedImageLookup: false,
            fallbackSystemImage: "dumbbell.fill",
            fallbackTitle: option.title
        )
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
            detail: String(localized: "Pecs"),
            systemImage: "figure.strengthtraining.traditional",
            muscles: ["Chest"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "shoulders",
            title: "Shoulders",
            detail: String(localized: "Delts"),
            systemImage: "figure.strengthtraining.functional",
            muscles: ["Shoulders"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "abdominals",
            title: "Abdominals",
            detail: String(localized: "Abdominals"),
            systemImage: "figure.core.training",
            muscles: ["Abdominals"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "biceps",
            title: "Biceps",
            detail: String(localized: "Front upper arm"),
            systemImage: "dumbbell.fill",
            muscles: ["Biceps"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "triceps",
            title: "Triceps",
            detail: String(localized: "Back upper arm"),
            systemImage: "dumbbell.fill",
            muscles: ["Triceps"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "forearms",
            title: "Forearms",
            detail: String(localized: "Grip and lower arm"),
            systemImage: "dumbbell.fill",
            muscles: ["Forearms"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "lats",
            title: "Lats",
            detail: String(localized: "Width-focused back"),
            systemImage: "figure.pullup",
            muscles: ["Lats"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "middle_back",
            title: "Middle Back",
            detail: String(localized: "Rows and upper-back thickness"),
            systemImage: "figure.pullup",
            muscles: ["Middle Back"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "lower_back",
            title: "Lower Back",
            detail: String(localized: "Spinal erectors"),
            systemImage: "figure.flexibility",
            muscles: ["Lower Back"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "traps",
            title: "Traps",
            detail: String(localized: "Upper back and neck line"),
            systemImage: "figure.strengthtraining.functional",
            muscles: ["Traps"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "quadriceps",
            title: "Quadriceps",
            detail: String(localized: "Quadriceps"),
            systemImage: "figure.run",
            muscles: ["Quadriceps"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "hamstrings",
            title: "Hamstrings",
            detail: String(localized: "Posterior thigh"),
            systemImage: "figure.run",
            muscles: ["Hamstrings"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "glutes",
            title: "Glutes",
            detail: String(localized: "Hips and glutes"),
            systemImage: "figure.run",
            muscles: ["Glutes"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "calves",
            title: "Calves",
            detail: String(localized: "Lower leg"),
            systemImage: "figure.run",
            muscles: ["Calves"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "abductors",
            title: "Abductors",
            detail: String(localized: "Outer hip"),
            systemImage: "figure.walk",
            muscles: ["Abductors"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "adductors",
            title: "Adductors",
            detail: String(localized: "Inner thigh"),
            systemImage: "figure.walk",
            muscles: ["Adductors"],
            isComposite: false
        ),
        ProfileTargetMuscleGroup(
            id: "neck",
            title: "Neck",
            detail: String(localized: "Neck"),
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
            return String(localized: "None")
        }
        if titles.count <= 2 {
            return titles.joined(separator: ", ")
        }
        return String(localized: "\(titles.count) selected")
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
            title: String(localized: "Upper Body"),
            detail: String(localized: "Chest and shoulders."),
            groupIDs: ["chest", "shoulders"]
        ),
        ProfileTargetMuscleSection(
            id: "back",
            title: String(localized: "Back"),
            detail: String(localized: "Choose the exact back area."),
            groupIDs: ["lats", "middle_back", "lower_back", "traps"]
        ),
        ProfileTargetMuscleSection(
            id: "arms",
            title: String(localized: "Arms"),
            detail: String(localized: "Biceps, triceps, and forearms are separate."),
            groupIDs: ["biceps", "triceps", "forearms"]
        ),
        ProfileTargetMuscleSection(
            id: "core",
            title: String(localized: "Core"),
            detail: String(localized: "Abdominal work."),
            groupIDs: ["abdominals"]
        ),
        ProfileTargetMuscleSection(
            id: "legs",
            title: String(localized: "Legs / Hips"),
            detail: String(localized: "Every primary lower-body target stays separate."),
            groupIDs: ["quadriceps", "hamstrings", "glutes", "calves", "abductors", "adductors"]
        ),
        ProfileTargetMuscleSection(
            id: "neck",
            title: String(localized: "Neck"),
            detail: String(localized: "Optional neck focus."),
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
                ProfileFieldRow(title: String(localized: "Target muscles"), systemImage: "scope") {
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

                    ProfileSelectionActionRow(
                        selectAllDisabled: selectableMuscles.isEmpty || selectableMuscles.isSubset(of: selection),
                        clearAllDisabled: selection.isEmpty,
                        selectAll: {
                            selection = selectableMuscles
                        },
                        clearAll: {
                            selection.removeAll()
                        }
                    )

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

    private var selectableMuscles: Set<String> {
        Set(sections.flatMap { section in
            section.groups(allowedValues: allowedValues)
                .flatMap { $0.availableMuscles(allowedValues: allowedValues) }
        })
    }
}

private struct ProfileSelectionActionRow: View {
    let selectAllDisabled: Bool
    let clearAllDisabled: Bool
    let selectAll: () -> Void
    let clearAll: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ProfileSelectionActionButton(
                title: String(localized: "Select all"),
                systemImage: "checkmark.circle",
                isDisabled: selectAllDisabled,
                action: selectAll
            )

            ProfileSelectionActionButton(
                title: String(localized: "Clear all"),
                systemImage: "xmark.circle",
                isDisabled: clearAllDisabled,
                action: clearAll
            )
        }
    }
}

private struct ProfileSelectionActionButton: View {
    let title: String
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(isDisabled ? Color.deltsMutedText.opacity(0.55) : Color.deltsAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.deltsPanel.opacity(isDisabled ? 0.12 : 0.28), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.deltsHairline.opacity(isDisabled ? 0.18 : 0.42), lineWidth: 0.7)
                }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .deltsPressable()
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
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Color.deltsOnAccent)
                            .frame(width: 25, height: 25)
                            .background(Color.deltsAccent, in: Circle())
                            .overlay {
                                Circle()
                                    .stroke(Color.deltsOnAccent.opacity(0.20), lineWidth: 0.7)
                            }
                            .padding(7)
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
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 158, alignment: .topLeading)
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
