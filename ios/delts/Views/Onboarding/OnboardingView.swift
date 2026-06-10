import StoreKit
import SwiftData
import SwiftUI
import UIKit

private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case personal
    case body
    case goals
    case preferences
    case rate
    case terms
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @AppStorage("delts_onboarding_complete") private var onboardingComplete = false
    @AppStorage("delts_terms_accepted_at") private var termsAcceptedAt = 0.0

    @State private var stepIndex = 0
    @State private var agreedToTerms = false
    @State private var didRequestReview = false

    private let steps = OnboardingStep.allCases

    private var step: OnboardingStep { steps[min(stepIndex, steps.count - 1)] }

    var body: some View {
        Group {
            if let profile = profiles.first {
                content(profile: profile)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color.deltsAccent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .deltsScreen()
        .task { ensureProfile() }
    }

    // MARK: - Layout

    private func content(profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            progressHeader

            ScrollView {
                stepBody(profile: profile)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            bottomBar
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if stepIndex > 0 {
                    Button {
                        withAnimation(.snappy(duration: 0.25)) { stepIndex -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.deltsCharcoal)
                            .frame(width: 36, height: 36)
                            .background(Color.deltsPanel.opacity(0.3), in: Circle())
                    }
                    .deltsPressable()
                    .transition(.opacity)
                }

                HStack(spacing: 6) {
                    ForEach(steps.indices, id: \.self) { index in
                        Capsule()
                            .fill(index <= stepIndex ? Color.deltsAccent : Color.deltsPanel.opacity(0.45))
                            .frame(height: 4)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private func stepBody(profile: UserProfile) -> some View {
        switch step {
        case .welcome:
            welcomeStep
        case .personal:
            profileStep(
                profile: profile,
                title: "Your details",
                subtitle: "A few basics so Delts can tailor plans to you.",
                section: .personalDetails
            )
        case .body:
            profileStep(
                profile: profile,
                title: "Body metrics",
                subtitle: "Used for progress tracking and calorie estimates.",
                section: .bodyMetrics
            )
        case .goals:
            profileStep(
                profile: profile,
                title: "Training goals",
                subtitle: "What you want out of your training.",
                section: .trainingGoals
            )
        case .preferences:
            profileStep(
                profile: profile,
                title: "Workout preferences",
                subtitle: "How and where you like to train.",
                section: .workoutPreferences
            )
        case .rate:
            rateStep
        case .terms:
            termsStep
        }
    }

    private func profileStep(profile: UserProfile, title: String, subtitle: String, section: ProfileSectionKind) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(title, subtitle)
            ProfileEditorView(profile: profile, sections: [section], embedded: true)
        }
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(DeltsTheme.current.previewAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 10) {
                Text("Welcome to Delts")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.deltsCharcoal)
                Text("A gym app built around the red session timer. Let's set up your profile so plans, progress, and calorie estimates fit you.")
                    .font(.body)
                    .foregroundStyle(Color.deltsMutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                onboardingHighlight("figure.strengthtraining.traditional", "Plan and time your sessions")
                onboardingHighlight("chart.line.uptrend.xyaxis", "Track weight, body fat, and history")
                onboardingHighlight("sparkles", "AI coach and calorie estimates")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func onboardingHighlight(_ systemImage: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 30, height: 30)
                .background(Color.deltsAccent.opacity(0.12), in: Circle())
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
        }
    }

    // MARK: - Rate

    private var rateStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader("Enjoying Delts?", "A rating helps other lifters find the app. It only takes a second.")

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.deltsAccent)
                    }
                }

                Button {
                    requestReview()
                    didRequestReview = true
                } label: {
                    Label(didRequestReview ? "Thanks!" : "Rate Delts", systemImage: didRequestReview ? "checkmark" : "star.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.deltsOnAccent)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(Color.deltsAccent, in: Capsule())
                }
                .deltsPressable()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.22), lineWidth: 0.5)
            }

            Text("You can rate or review anytime from Settings → About.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Terms

    private var termsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader("One last thing", "Review and accept to start using Delts.")

            VStack(alignment: .leading, spacing: 16) {
                Text("By continuing you agree to the Delts [Terms](https://delts.fit/terms) and [Privacy Policy](https://delts.fit/privacy). Delts is not medical advice — consult a professional before changing your training.")
                    .font(.subheadline)
                    .foregroundStyle(Color.deltsCharcoal)
                    .tint(Color.deltsAccent)
                    .fixedSize(horizontal: false, vertical: true)

                Toggle(isOn: $agreedToTerms) {
                    Text("I agree to the Terms and Privacy Policy")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.deltsCharcoal)
                }
                .tint(Color.deltsAccent)

                HStack(spacing: 18) {
                    Button("Privacy Policy") { open("https://delts.fit/privacy") }
                    Button("Terms") { open("https://delts.fit/terms") }
                }
                .font(.caption.weight(.bold))
                .tint(Color.deltsSecondaryAccent)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.22), lineWidth: 0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            PrimaryButton(
                title: primaryTitle,
                systemImage: primarySystemImage
            ) {
                advance()
            }
            .disabled(step == .terms && !agreedToTerms)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 8)
        }
        .deltsBottomActionBackground()
    }

    private var primaryTitle: String {
        switch step {
        case .welcome: return "Get Started"
        case .terms: return "Start Training"
        default: return "Continue"
        }
    }

    private var primarySystemImage: String {
        switch step {
        case .terms: return "checkmark.circle.fill"
        default: return "arrow.right"
        }
    }

    // MARK: - Actions

    private func advance() {
        if step == .terms {
            finish()
            return
        }
        try? modelContext.save()
        withAnimation(.snappy(duration: 0.25)) {
            stepIndex = min(stepIndex + 1, steps.count - 1)
        }
    }

    private func finish() {
        guard agreedToTerms else { return }
        try? modelContext.save()
        termsAcceptedAt = Date().timeIntervalSince1970
        onboardingComplete = true
    }

    private func stepHeader(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.deltsMutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ensureProfile() {
        guard profiles.isEmpty else { return }
        modelContext.insert(UserProfile.defaultProfile())
        try? modelContext.save()
    }

    private func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        openURL(url)
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
