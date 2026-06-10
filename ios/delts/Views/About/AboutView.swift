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
                    AboutSection(title: "Release") {
                        AboutRowStack {
                            AboutActionRow(
                                title: "Check for Updates",
                                systemImage: "arrow.down.circle.fill",
                                value: appVersionText,
                                tint: .deltsSecondaryAccent
                            ) {
                                checkForUpdates()
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: "Rate Delts",
                                systemImage: "star.fill",
                                value: "Native prompt",
                                tint: .deltsSecondaryAccent
                            ) {
                                requestAppReview()
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: "Share Delts",
                                systemImage: "square.and.arrow.up",
                                value: "App Store link",
                                tint: .deltsSecondaryAccent
                            ) {
                                shareApp()
                            }
                        }
                    }

                    AboutSection(title: "Feedback") {
                        AboutRowStack {
                            AboutActionRow(
                                title: "Report an Issue",
                                systemImage: "exclamationmark.bubble.fill",
                                value: "GitHub",
                                tint: .red
                            ) {
                                open(AboutLinks.githubIssueURL)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: "Request a Feature",
                                systemImage: "lightbulb.fill",
                                value: "GitHub",
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.githubFeatureURL)
                            }
                        }
                    }

                    AboutSection(title: "Contact") {
                        AboutRowStack {
                            AboutActionRow(
                                title: "Contact Us",
                                systemImage: "envelope.fill",
                                value: AboutLinks.contactEmail,
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.contactEmailURL)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: "Follow on X",
                                systemImage: "at",
                                value: "@apoorvdarshan",
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.xProfileURL)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: "Instagram",
                                systemImage: "camera.fill",
                                value: "Coming soon",
                                tint: .deltsSecondaryAccent
                            ) {
                                activeAlert = .placeholder(.instagram)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: "LinkedIn",
                                systemImage: "person.crop.square.filled.and.at.rectangle",
                                value: "Coming soon",
                                tint: .deltsSecondaryAccent
                            ) {
                                activeAlert = .placeholder(.linkedIn)
                            }
                        }
                    }

                    AboutSection(title: "Support & Links") {
                        AboutRowStack {
                            AboutActionRow(
                                title: "Support on Ko-fi",
                                systemImage: "cup.and.saucer.fill",
                                value: "apoorvdarshan",
                                tint: .deltsSecondaryAccent
                            ) {
                                open(AboutLinks.kofiURL)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: "Open Source",
                                systemImage: "curlybraces.square.fill",
                                value: "Repo soon",
                                tint: .deltsSecondaryAccent
                            ) {
                                activeAlert = .placeholder(.openSource)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: "Product Hunt",
                                systemImage: "paperplane.fill",
                                value: "Coming soon",
                                tint: .deltsSecondaryAccent
                            ) {
                                activeAlert = .placeholder(.productHunt)
                            }
                        }
                    }

                    AboutSection(title: "Built by") {
                        VStack(spacing: 14) {
                            AboutRowStack {
                                AboutActionRow(
                                    title: "Apoorv Darshan",
                                    systemImage: "person.fill",
                                    value: "Creator",
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

                    AboutSection(title: "Legal") {
                        AboutRowStack {
                            AboutActionRow(
                                title: "Privacy Policy",
                                systemImage: "hand.raised.fill",
                                value: "delts.fit/privacy",
                                tint: .deltsSecondaryAccent
                            ) {
                                activeAlert = .placeholder(.privacy)
                            }
                            AboutDivider()
                            AboutActionRow(
                                title: "Terms",
                                systemImage: "doc.text.fill",
                                value: "delts.fit/terms",
                                tint: .deltsSecondaryAccent
                            ) {
                                activeAlert = .placeholder(.terms)
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
        return "Unavailable"
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
            let message = "Version \(version) is available. You are on \(appVersionText)."
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
            let latestText = latestVersion.map { " Latest App Store version: \($0)." } ?? ""
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
    static let appStoreShareURL: URL? = nil
    static let contactEmail = "ad13dtu@gmail.com"
    static let contactEmailURL = URL(string: "mailto:\(contactEmail)")
    static let githubIssueURL = URL(string: "https://github.com/apoorvdarshan/delts/issues/new")
    static let githubFeatureURL = URL(string: "https://github.com/apoorvdarshan/delts/issues/new?labels=enhancement")
    static let kofiURL = URL(string: "https://ko-fi.com/apoorvdarshan")
    static let xProfileURL = URL(string: "https://x.com/apoorvdarshan")
}

private enum AboutPlaceholder: Identifiable {
    case share
    case openSource
    case productHunt
    case instagram
    case linkedIn
    case privacy
    case terms

    var id: String {
        title
    }

    var title: String {
        switch self {
        case .share: return "Share Delts"
        case .openSource: return "Open Source"
        case .productHunt: return "Product Hunt"
        case .instagram: return "Instagram"
        case .linkedIn: return "LinkedIn"
        case .privacy: return "Privacy Policy"
        case .terms: return "Terms"
        }
    }

    var message: String {
        switch self {
        case .share:
            return "The App Store share link will be added when the listing is ready."
        case .openSource:
            return "The repository is private for now. This row is ready for the public open-source repo link later."
        case .productHunt:
            return "The Product Hunt launch link will be added when it is ready."
        case .instagram:
            return "The Instagram profile link will be added later."
        case .linkedIn:
            return "The LinkedIn profile link will be added later."
        case .privacy:
            return "This will open delts.fit/privacy after the website is configured."
        case .terms:
            return "This will open delts.fit/terms after the website is configured."
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
