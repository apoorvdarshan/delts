import Foundation
import StoreKit
import SwiftUI
import UIKit

struct AboutView: View {
    @ObservedObject var updateChecker: AppUpdateChecker

    var body: some View {
        NavigationStack {
            ScrollView {
                AboutSettingsSection(updateChecker: updateChecker, scope: .about)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 120)
            }
            .deltsScreen()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

/// Which half of the settings/about content a section list renders.
enum AboutSectionScope {
    case settings
    case about
}

struct AboutSettingsSection: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var updateChecker: AppUpdateChecker
    var scope: AboutSectionScope
    @State private var activeAlert: AboutAlert?
    @State private var whatsNewExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if scope != .about {
                    AboutSection(title: String(localized: "Release")) {
                        AboutRowStack {
                            CheckForUpdatesRow(updateChecker: updateChecker, version: appVersionText)
                            AboutDivider()
                            WhatsNewRow(
                                version: appVersionText,
                                isExpanded: $whatsNewExpanded
                            )
                            AboutDivider()
                            AboutActionRow(
                                title: String(localized: "Rate Delts"),
                                systemImage: "star.fill",
                                value: String(localized: "Native prompt"),
                                tint: .deltsSecondaryAccent
                            ) {
                                requestAppReview()
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: String(localized: "Share Delts"),
                                systemImage: "square.and.arrow.up",
                                value: String(localized: "App Store link"),
                                tint: .deltsSecondaryAccent
                            ) {
                                shareApp()
                            }
                        }
                    }

                    AboutSection(title: String(localized: "Feedback")) {
                        AboutRowStack {
                            AboutActionRow(
                                title: String(localized: "Report an Issue"),
                                systemImage: "exclamationmark.bubble.fill",
                                value: String(localized: "GitHub"),
                                tint: .red
                            ) {
                                open(AboutLinks.githubIssueURL)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: String(localized: "Request a Feature"),
                                systemImage: "lightbulb.fill",
                                value: String(localized: "GitHub"),
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.githubFeatureURL)
                            }
                        }
                    }
            }

            if scope != .settings {
                    AboutSection(title: String(localized: "Connect")) {
                        AboutRowStack {
                            AboutActionRow(
                                title: String(localized: "Contact Us"),
                                systemImage: "envelope.fill",
                                value: AboutLinks.contactEmail,
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.contactEmailURL)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: String(localized: "Follow on X"),
                                systemImage: "at",
                                value: "@apoorvdarshan",
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.xProfileURL)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: String(localized: "Instagram"),
                                systemImage: "camera.fill",
                                value: "@delts.fit",
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.instagramURL)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: String(localized: "LinkedIn"),
                                systemImage: "person.crop.square.filled.and.at.rectangle",
                                value: "Delts",
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.linkedInURL)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: String(localized: "Open Source"),
                                systemImage: "curlybraces.square.fill",
                                value: String(localized: "GitHub"),
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.githubRepoURL)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: String(localized: "Product Hunt"),
                                systemImage: "paperplane.fill",
                                value: String(localized: "Vote for Delts"),
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.productHuntURL)
                            }
                        }
                    }

                    AboutSection(title: String(localized: "Support")) {
                        AboutRowStack {
                            SupportTipPicker()
                        }
                    }

                    AboutSection(title: String(localized: "Built by")) {
                        VStack(spacing: 14) {
                            AboutRowStack {
                                AboutActionRow(
                                    title: "Apoorv Darshan",
                                    systemImage: "person.fill",
                                    value: String(localized: "Creator"),
                                    tint: .deltsSecondaryAccent
                                ) {
                                    open(AboutLinks.xProfileURL)
                                }
                            }

                            VStack(spacing: 10) {
                                Image("ACEBadge")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 104, height: 104)
                                    .accessibilityLabel("ACE Certified Personal Trainer")

                                Text("ACE Certified Personal Trainer")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.deltsMutedText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(Color.deltsHairline.opacity(0.22), lineWidth: 0.5)
                            }
                        }
                    }

                    AboutSection(title: String(localized: "Legal")) {
                        AboutRowStack {
                            AboutActionRow(
                                title: String(localized: "Privacy Policy"),
                                systemImage: "hand.raised.fill",
                                value: "delts.fit/privacy",
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.privacyURL)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: String(localized: "Terms"),
                                systemImage: "doc.text.fill",
                                value: "delts.fit/terms",
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.termsURL)
                            }
                        }
                    }
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case let .placeholder(placeholder):
                return Alert(
                    title: Text(placeholder.title),
                    message: Text(placeholder.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        if let version, !version.isEmpty {
            return version
        }
        return String(localized: "Unavailable")
    }

    private func requestAppReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return }

        SKStoreReviewController.requestReview(in: scene)
    }

    private func shareApp() {
        guard let url = updateChecker.appStoreURL ?? AboutLinks.appStoreShareURL else {
            activeAlert = .placeholder(.share)
            return
        }

        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootController = scene.deltsPrimaryWindow?.rootViewController
        else { return }

        rootController.deltsTopPresentedController.present(activityController, animated: true)
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        openURL(url)
    }

}

/// "Check for Updates" row: runs the check inline with a spinner and shows the
/// result on the row itself (no popup). What's New lives in the row below.
private struct CheckForUpdatesRow: View {
    @ObservedObject var updateChecker: AppUpdateChecker
    let version: String
    @Environment(\.openURL) private var openURL
    @State private var statusText: String?
    @State private var storeURL: URL?

    var body: some View {
        Button {
            if let storeURL {
                openURL(storeURL)
            } else {
                runCheck()
            }
        } label: {
            AboutFieldRow(title: String(localized: "Check for Updates"), systemImage: "arrow.down.circle.fill", tint: .deltsSecondaryAccent) {
                trailing
            }
        }
        .deltsPressable()
        .disabled(updateChecker.isChecking)
    }

    @ViewBuilder
    private var trailing: some View {
        if updateChecker.isChecking {
            ProgressView()
                .controlSize(.small)
                .tint(Color.deltsAccent)
                .frame(minWidth: 72, minHeight: 38, alignment: .trailing)
        } else {
            AboutValueLabel(text: statusText ?? version, showsChevron: storeURL != nil)
        }
    }

    private func runCheck() {
        guard !updateChecker.isChecking else { return }
        Task {
            let result = await updateChecker.checkForUpdates()
            withAnimation(.snappy(duration: 0.2)) {
                apply(result)
            }
            // A non-actionable result (up to date / failed) clears after a moment,
            // returning the row to showing the current version like before.
            if storeURL == nil {
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation(.snappy(duration: 0.2)) {
                    statusText = nil
                }
            }
        }
    }

    private func apply(_ result: AppUpdateCheckResult) {
        switch result {
        case let .available(_, url, _):
            statusText = String(localized: "Update available")
            storeURL = url
        case .upToDate, .unavailable:
            statusText = String(localized: "Up to date")
            storeURL = nil
        case .failed:
            statusText = String(localized: "Check failed — try again")
            storeURL = nil
        case .idle, .checking:
            break
        }
    }
}

private enum AboutLinks {
    static let appStoreShareURL: URL? = URL(string: "https://apps.apple.com/app/id6778653288")
    static let contactEmail = "ad13dtu@gmail.com"
    static let contactEmailURL = URL(string: "mailto:\(contactEmail)")
    static let githubIssueURL = URL(string: "https://github.com/apoorvdarshan/delts/issues/new")
    static let githubFeatureURL = URL(string: "https://github.com/apoorvdarshan/delts/issues/new?labels=enhancement")
    static let xProfileURL = URL(string: "https://x.com/apoorvdarshan")
    static let instagramURL = URL(string: "https://www.instagram.com/delts.fit")
    static let linkedInURL = URL(string: "https://www.linkedin.com/company/delts")
    static let productHuntURL = URL(string: "https://www.producthunt.com/products/delts")
    static let githubRepoURL = URL(string: "https://github.com/apoorvdarshan/delts")
    static let privacyURL = URL(string: "https://delts.fit/privacy.html")
    static let termsURL = URL(string: "https://delts.fit/terms.html")
}

private enum AboutPlaceholder: Identifiable {
    case share

    var id: String {
        title
    }

    var title: String {
        switch self {
        case .share: return String(localized: "Share Delts")
        }
    }

    var message: String {
        switch self {
        case .share:
            return String(localized: "The App Store share link will be added when the listing is ready.")
        }
    }
}

private enum AboutAlert: Identifiable {
    case placeholder(AboutPlaceholder)

    var id: String {
        switch self {
        case let .placeholder(placeholder):
            return "placeholder-\(placeholder.id)"
        }
    }
}

private struct AboutSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.callout.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
                .padding(.horizontal, 14)

            content
        }
    }
}

private struct AboutRowStack<Content: View>: View {
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

private struct AboutDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.28))
            .frame(height: 0.5)
            .padding(.leading, 48)
    }
}

private struct AboutActionRow: View {
    let title: String
    let systemImage: String
    let value: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AboutFieldRow(title: title, systemImage: systemImage, tint: tint) {
                AboutValueLabel(text: value, showsChevron: true)
            }
        }
        .deltsPressable()
    }
}

private struct AboutFieldRow<Content: View>: View {
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
                AboutFieldLabel(title: title, systemImage: systemImage, tint: tint)
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        } else {
            HStack(alignment: .center, spacing: 12) {
                AboutFieldLabel(title: title, systemImage: systemImage, tint: tint)
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

/// Bundled, in-app release notes for the current version. Update `highlights`
/// each release; the version header is read live from the app bundle.
enum DeltsReleaseNotes {
    static let highlights: [String] = [
        String(localized: "Delts is now a free, focused exercise library — browse hundreds of moves with form instructions and rich filters."),
        String(localized: "Rebuilt around three simple tabs: Workouts, Settings, and About."),
        String(localized: "Completely private — no account, no ads, no tracking. Everything stays on your device."),
        String(localized: "Lighter and faster, with a cleaner Settings layout and inline update checks.")
    ]
}

/// Expandable "What's New" row: tap to reveal the current version's highlights.
private struct WhatsNewRow: View {
    let version: String
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.28)) { isExpanded.toggle() }
            } label: {
                AboutFieldRow(title: String(localized: "What's New"), systemImage: "sparkles", tint: .deltsSecondaryAccent) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText.opacity(0.72))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(minWidth: 72, minHeight: 38, alignment: .trailing)
                }
            }
            .deltsPressable()
            .accessibilityLabel(String(localized: "What's New"))
            .accessibilityValue(isExpanded ? String(localized: "Expanded") : String(localized: "Collapsed"))

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Delts \(version)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)

                    ForEach(DeltsReleaseNotes.highlights, id: \.self) { line in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.deltsAccent)
                                .padding(.top, 1)

                            Text(line)
                                .font(.subheadline)
                                .foregroundStyle(Color.deltsMutedText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 49)
                .padding(.trailing, 4)
                .padding(.top, 2)
                .padding(.bottom, 14)
                .transition(.opacity)
            }
        }
        .clipped()
    }
}

private struct AboutFieldLabel: View {
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

private struct AboutValueLabel: View {
    let text: String
    let showsChevron: Bool

    var body: some View {
        HStack(spacing: 7) {
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.trailing)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText.opacity(0.72))
            }
        }
        .frame(minWidth: 72, maxWidth: 180, minHeight: 38, alignment: .trailing)
    }
}

private extension UIWindowScene {
    var deltsPrimaryWindow: UIWindow? {
        windows.first(where: \.isKeyWindow) ?? windows.first
    }
}

private extension UIViewController {
    var deltsTopPresentedController: UIViewController {
        presentedViewController?.deltsTopPresentedController ?? self
    }
}

// MARK: - Support tip picker (inline, echoes the Theme swatch grid)

/// Inline "Support Delts" tip jar for the About screen. Echoes the Theme picker:
/// every available tip tier is shown at once as a tappable tile, and tapping one
/// launches the StoreKit purchase directly — the system sheet is the confirm. No
/// sheet, no select-then-confirm. The whole app stays free; tips unlock nothing.
private struct SupportTipPicker: View {
    @ObservedObject private var store = TipStore.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Pixel-art tier icons by ascending price index (small / medium / large).
    private let tierAsset = ["TipSmall", "TipMedium", "TipLarge"]

    /// Which tip is mid-purchase, so only that tile shows the spinner + accent.
    @State private var purchasingID: String?
    /// Drives the one-shot heart bounce on the thanks state.
    @State private var celebrate = false

    /// One flexible column per available tip — mirrors the Theme grid exactly.
    private var columns: [GridItem] {
        store.tips.map { _ in GridItem(.flexible(), spacing: 8) }
    }

    var body: some View {
        // A control block like the Theme/Profile blocks: a steady label over the
        // swappable content. Lives inside AboutRowStack's card, so it inherits the
        // exact surface + inset (no new surface code, no doubled card).
        VStack(alignment: .leading, spacing: 10) {
            AboutFieldLabel(
                title: String(localized: "Support Delts"),
                systemImage: "heart.fill",
                tint: .deltsAccent
            )

            Group {
                if store.showThanks {
                    thanks
                } else {
                    content
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.snappy(duration: 0.28), value: store.showThanks)
        .animation(.snappy(duration: 0.28), value: store.isLoading)
        .animation(.snappy(duration: 0.28), value: store.tips.count)
        .animation(.easeOut(duration: 0.2), value: store.lastErrorMessage)
        .task { await store.loadTips() }
        .sensoryFeedback(trigger: store.showThanks) { _, isThanks in
            isThanks ? .success : nil
        }
        .onChange(of: store.showThanks) { _, isThanks in
            guard isThanks else {
                celebrate = false
                return
            }
            // Inline picker: gently revert the celebration back to the tiles.
            Task {
                try? await Task.sleep(for: .seconds(2.4))
                store.showThanks = false
            }
        }
        .onChange(of: store.lastErrorMessage) { _, message in
            // Inline, auto-clearing error — no alert, matching this section's ethos.
            guard message != nil else { return }
            Task {
                try? await Task.sleep(for: .seconds(4))
                store.lastErrorMessage = nil
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Delts is free forever — tips are optional and unlock nothing.")
                .font(.footnote)
                .foregroundStyle(Color.deltsMutedText)
                .fixedSize(horizontal: false, vertical: true)

            if store.tips.isEmpty {
                if store.isLoading {
                    loading
                } else {
                    unavailable
                }
            } else {
                tiles
            }

            if let message = store.lastErrorMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.deltsWarning)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var tiles: some View {
        // 3-up grid normally; collapse to a full-width vertical stack at
        // accessibility text sizes so emoji + name + price never get crushed.
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 8) {
                tileForEach
            }
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                tileForEach
            }
        }
    }

    private var tileForEach: some View {
        ForEach(Array(store.tips.enumerated()), id: \.element.id) { index, product in
            SupportTipTile(
                product: product,
                assetName: tierAsset[min(index, tierAsset.count - 1)],
                isPurchasing: store.isPurchasing && purchasingID == product.id,
                isDisabled: store.isPurchasing
            ) {
                purchase(product)
            }
        }
    }

    private var loading: some View {
        ProgressView()
            .controlSize(.regular)
            .tint(Color.deltsAccent)
            .frame(maxWidth: .infinity, minHeight: 92)
            .accessibilityLabel(String(localized: "Loading tip options"))
    }

    private var unavailable: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tips aren't available right now.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await store.loadTips() }
            } label: {
                Text("Tap to try again")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.deltsAccent)
            }
            .buttonStyle(.plain)
            .deltsPressable()
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
    }

    private var thanks: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.deltsAccent)
                .scaleEffect(celebrate || reduceMotion ? 1 : 0.6)
                .symbolEffect(.bounce, value: celebrate && !reduceMotion)

            Text("Thank you 💚")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)

            Text("Your support keeps Delts free for everyone.")
                .font(.caption)
                .foregroundStyle(Color.deltsMutedText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 116)
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Thank you for supporting Delts. The app stays free."))
        .onAppear {
            purchasingID = nil
            if reduceMotion {
                celebrate = true
            } else {
                celebrate = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    celebrate = true
                }
            }
        }
    }

    private func purchase(_ product: Product) {
        guard !store.isPurchasing else { return }
        store.lastErrorMessage = nil
        purchasingID = product.id
        Task {
            await store.purchase(product) // triggers the system purchase UI
            purchasingID = nil            // success flips store.showThanks itself
        }
    }
}

/// One tip tier tile — a faithful clone of the Theme option tile, with the tier
/// emoji where the icon preview sits and the tier name + price stacked beneath.
/// The selected look is reused to signal an in-flight purchase.
private struct SupportTipTile: View {
    let product: Product
    let assetName: String
    let isPurchasing: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                ZStack {
                    if isPurchasing {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.deltsAccent)
                    } else {
                        Image(assetName)
                            .resizable()
                            .interpolation(.none) // keep the pixel art crisp
                            .scaledToFit()
                            .padding(1)
                    }
                }
                .frame(width: 44, height: 44)

                VStack(spacing: 2) {
                    Text(product.displayName)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(isPurchasing ? Color.deltsCharcoal : Color.deltsMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(product.displayPrice)
                        .font(.caption2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.deltsAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, minHeight: 92)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isPurchasing ? Color.deltsAccent.opacity(0.16) : Color.deltsPanel.opacity(0.20))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isPurchasing ? Color.deltsAccent.opacity(0.78) : Color.deltsHairline.opacity(0.26),
                        lineWidth: isPurchasing ? 1.2 : 0.6
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isDisabled && !isPurchasing ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .deltsPressable()
        .disabled(isDisabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(product.displayName), \(product.displayPrice)")
        .accessibilityHint(String(localized: "Leaves an optional tip to support Delts"))
        .accessibilityValue(isPurchasing ? Text(String(localized: "Purchasing")) : Text(""))
        .accessibilityAddTraits(.isButton)
    }
}
