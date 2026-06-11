import Foundation
import StoreKit
import SwiftUI
import UIKit

struct AboutView: View {
    @ObservedObject var updateChecker: AppUpdateChecker

    var body: some View {
        NavigationStack {
            ScrollView {
                AboutSettingsSection(updateChecker: updateChecker)
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

struct AboutSettingsSection: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var updateChecker: AppUpdateChecker
    @State private var activeAlert: AboutAlert?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
                    AboutSection(title: String(localized: "Release")) {
                        AboutRowStack {
                            AboutActionRow(
                                title: String(localized: "Check for Updates"),
                                systemImage: "arrow.down.circle.fill",
                                value: appVersionText,
                                tint: .deltsSecondaryAccent
                            ) {
                                checkForUpdates()
                            }
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

                    AboutSection(title: String(localized: "Contact")) {
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
                        }
                    }

                    AboutSection(title: String(localized: "Support & Links")) {
                        AboutRowStack {
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
        .alert(item: $activeAlert) { alert in
            switch alert {
            case let .placeholder(placeholder):
                return Alert(
                    title: Text(placeholder.title),
                    message: Text(placeholder.message),
                    dismissButton: .default(Text("OK"))
                )
            case let .update(result):
                return updateAlert(for: result)
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

    private func checkForUpdates() {
        guard !updateChecker.isChecking else { return }

        Task {
            let result = await updateChecker.checkForUpdates()
            activeAlert = .update(result)
        }
    }

    private func updateAlert(for result: AppUpdateCheckResult) -> Alert {
        switch result {
        case .idle, .checking:
            return Alert(
                title: Text("Checking for Updates"),
                message: Text("Delts is checking the App Store for a newer version."),
                dismissButton: .default(Text("OK"))
            )
        case let .available(version, storeURL):
            let message = String(localized: "Version \(version) is available. You are on \(appVersionText).")
            if let storeURL {
                return Alert(
                    title: Text("Update Available"),
                    message: Text(message),
                    primaryButton: .default(Text("Open")) {
                        open(storeURL)
                    },
                    secondaryButton: .cancel()
                )
            }

            return Alert(
                title: Text("Update Available"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        case let .upToDate(latestVersion):
            let latestText = latestVersion.map { String(localized: " Latest App Store version: \($0).") } ?? ""
            return Alert(
                title: Text("Delts Is Up to Date"),
                message: Text("You are on \(appVersionText).\(latestText)"),
                dismissButton: .default(Text("OK"))
            )
        case .unavailable:
            return Alert(
                title: Text("Update Check Ready"),
                message: Text("The automatic update checker is ready. The App Store listing is not live for this bundle yet."),
                dismissButton: .default(Text("OK"))
            )
        case let .failed(message):
            return Alert(
                title: Text("Update Check Failed"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
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
    case update(AppUpdateCheckResult)

    var id: String {
        switch self {
        case let .placeholder(placeholder):
            return "placeholder-\(placeholder.id)"
        case .update:
            return "update"
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
