import Foundation
import SwiftUI

/// One-time user consent for sharing data with the AI service (Guideline 5.1.2).
/// AI requests are blocked until the user explicitly allows data sharing; the
/// decision can be reviewed and revoked from Settings at any time.
enum AIConsent {
    static let storageKey = "delts_ai_data_consent"

    static var isGranted: Bool {
        UserDefaults.standard.bool(forKey: storageKey)
    }

    /// Whether the user has ever been asked (distinguishes "declined" from "never asked").
    static var hasDecided: Bool {
        UserDefaults.standard.object(forKey: storageKey) != nil
    }

    static func set(_ granted: Bool) {
        UserDefaults.standard.set(granted, forKey: storageKey)
    }
}

/// Disclosure sheet shown before the first AI request. Explains exactly what
/// data is sent and to whom, and asks for permission.
struct AIConsentSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onDecision: (Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color.deltsAccent)

                        Text("Share data with the AI Coach?")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.deltsCharcoal)

                        Text("Delts AI features need to send some of your data off your device to answer you. Nothing is shared until you allow it.")
                            .font(.subheadline)
                            .foregroundStyle(Color.deltsMutedText)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        consentRow(
                            icon: "doc.text.fill",
                            title: String(localized: "What is sent"),
                            detail: String(localized: "Your Coach messages, photos you choose to attach, and training context: profile basics (age, sex, height, weight, body fat), goals, settings, recent workouts, and body progress. Calorie estimates send the finished session and your body data.")
                        )
                        consentRow(
                            icon: "arrow.up.forward.app.fill",
                            title: String(localized: "Who receives it"),
                            detail: String(localized: "The Delts server (delts.fit) and Google's Gemini API (Google LLC), which generates the response. Your data is not sold and is not used for advertising.")
                        )
                        consentRow(
                            icon: "hand.raised.fill",
                            title: String(localized: "Your choice"),
                            detail: String(localized: "If you don't allow sharing, all AI features stay off — everything else in Delts keeps working. You can change this anytime in Settings → AI Data Sharing.")
                        )
                    }
                    .padding(16)
                    .background(Color.deltsPanel.opacity(0.22), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    Link(destination: URL(string: "https://delts.fit/privacy.html")!) {
                        Text("Read the Privacy Policy")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.deltsSecondaryAccent)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 26)
                .padding(.bottom, 16)
            }

            VStack(spacing: 10) {
                Button {
                    AIConsent.set(true)
                    onDecision(true)
                    dismiss()
                } label: {
                    Text("Allow & Continue")
                        .font(.body.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.deltsAccent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .foregroundStyle(Color.deltsOnAccent)
                }

                Button {
                    AIConsent.set(false)
                    onDecision(false)
                    dismiss()
                } label: {
                    Text("Not Now")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(Color.deltsMutedText)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 14)
        }
        .presentationDetents([.large])
        .deltsScreen()
    }

    private func consentRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Color.deltsMutedText)
            }
        }
    }
}
