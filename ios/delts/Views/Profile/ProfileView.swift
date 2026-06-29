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
    @Bindable var profile: UserProfile
    var updateChecker: AppUpdateChecker?
    var sections: Set<ProfileSectionKind> = Set(ProfileSectionKind.allCases)
    var embedded: Bool = false
    @AppStorage(AppAppearance.storageKey) private var appAppearanceRaw = AppAppearance.system.rawValue
    @AppStorage(DeltsTheme.storageKey) private var deltsThemeRaw = DeltsTheme.lime.rawValue

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
            title: String(localized: "Library"),
            subtitle: String(localized: "Group the exercise library by your training split."),
            systemImage: "square.split.2x2"
        ) {
            ProfileRowStack {
                ProfileWorkoutSplitPickerRow(
                    title: String(localized: "Workout split"),
                    systemImage: "square.split.2x2",
                    selection: splitBinding
                )
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
