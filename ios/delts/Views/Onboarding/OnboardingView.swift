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
    @State private var goingForward = true
    @State private var agreedToTerms = false
    @State private var didRequestReview = false
    @State private var welcomeRevealed = false

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

            ZStack(alignment: .top) {
                ScrollView {
                    stepBody(profile: profile)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 28)
                }
                .scrollDismissesKeyboard(.interactively)
                .id(stepIndex)
                .transition(stepTransition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
        .background(alignment: .top) {
            RadialGradient(
                colors: [Color.deltsAccent.opacity(0.12), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 440
            )
            .ignoresSafeArea()
        }
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: goingForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: goingForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        HStack(spacing: 14) {
            if stepIndex > 0 {
                Button {
                    goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                        .frame(width: 34, height: 34)
                        .background(Color.deltsPanel.opacity(0.32), in: Circle())
                        .overlay(Circle().stroke(Color.deltsHairline.opacity(0.3), lineWidth: 0.5))
                }
                .deltsPressable()
                .transition(.opacity.combined(with: .scale(scale: 0.6)))
            }

            HStack(spacing: 6) {
                ForEach(steps.indices, id: \.self) { index in
                    Capsule()
                        .fill(index <= stepIndex ? Color.deltsAccent : Color.deltsPanel.opacity(0.5))
                        .frame(height: 4)
                        .shadow(
                            color: index == stepIndex ? Color.deltsAccent.opacity(0.65) : .clear,
                            radius: 5
                        )
                        .animation(.snappy(duration: 0.3), value: stepIndex)
                }
            }
        }
        .animation(.snappy(duration: 0.25), value: stepIndex)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Steps

    @ViewBuilder
    private func stepBody(profile: UserProfile) -> some View {
        switch step {
        case .welcome:
            welcomeStep
        case .personal:
            profileStep(
                profile: profile,
                icon: "person.fill",
                title: String(localized: "Your details"),
                subtitle: String(localized: "A few basics so Delts can tailor plans to you."),
                section: .personalDetails
            )
        case .body:
            profileStep(
                profile: profile,
                icon: "scalemass.fill",
                title: String(localized: "Body metrics"),
                subtitle: String(localized: "Used for progress tracking and calorie estimates."),
                section: .bodyMetrics
            )
        case .goals:
            profileStep(
                profile: profile,
                icon: "target",
                title: String(localized: "Training goals"),
                subtitle: String(localized: "What you want out of your training."),
                section: .trainingGoals
            )
        case .preferences:
            profileStep(
                profile: profile,
                icon: "slider.horizontal.3",
                title: String(localized: "Workout preferences"),
                subtitle: String(localized: "How and where you like to train."),
                section: .workoutPreferences
            )
        case .rate:
            rateStep
        case .terms:
            termsStep
        }
    }

    private func profileStep(
        profile: UserProfile,
        icon: String,
        title: String,
        subtitle: String,
        section: ProfileSectionKind
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader(icon: icon, title, subtitle)
            ProfileEditorView(profile: profile, sections: [section], embedded: true)
        }
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(spacing: 26) {
            Image("DeltsGlyph")
                .resizable()
                .scaledToFit()
                .frame(width: 116, height: 116)
                .scaleEffect(welcomeRevealed ? 1 : 0.84)
                .opacity(welcomeRevealed ? 1 : 0)
                .padding(.top, 16)

            VStack(spacing: 10) {
                Text("LET'S GET YOU SET UP")
                    .font(.caption.weight(.heavy))
                    .tracking(2.4)
                    .foregroundStyle(Color.deltsAccent)

                Text("Welcome to Delts")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.deltsCharcoal)
                    .multilineTextAlignment(.center)

                Text("A gym app built around the red session timer. Set up your profile so plans, progress, and calorie estimates fit you.")
                    .font(.subheadline)
                    .foregroundStyle(Color.deltsMutedText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }
            .opacity(welcomeRevealed ? 1 : 0)
            .offset(y: welcomeRevealed ? 0 : 14)

            VStack(spacing: 0) {
                welcomeHighlight(
                    "figure.strengthtraining.traditional",
                    String(localized: "Plan & time sessions"),
                    String(localized: "The red button runs your workout")
                )
                cardDivider
                welcomeHighlight(
                    "chart.line.uptrend.xyaxis",
                    String(localized: "Track your progress"),
                    String(localized: "Weight, body fat, and workout history")
                )
                cardDivider
                welcomeHighlight(
                    "sparkles",
                    String(localized: "AI Coach"),
                    String(localized: "Chat, photos, and calorie estimates")
                )
            }
            .padding(.vertical, 6)
            .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
            }
            .opacity(welcomeRevealed ? 1 : 0)
            .offset(y: welcomeRevealed ? 0 : 20)

            Text("Takes under a minute · Edit anytime in Settings")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText.opacity(0.85))
                .opacity(welcomeRevealed ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            guard !welcomeRevealed else { return }
            withAnimation(.spring(duration: 0.7, bounce: 0.22).delay(0.08)) {
                welcomeRevealed = true
            }
        }
    }

    private var cardDivider: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.22))
            .frame(height: 0.5)
            .padding(.leading, 64)
    }

    private func welcomeHighlight(_ systemImage: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 36, height: 36)
                .background(Color.deltsAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Rate

    private var rateStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader(icon: "star.fill", String(localized: "Enjoying Delts?"), String(localized: "A rating helps other lifters find the app. It only takes a second."))

            VStack(spacing: 22) {
                HStack(alignment: .center, spacing: 10) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.system(size: starSize(for: index), weight: .bold))
                            .foregroundStyle(Color.deltsAccent)
                            .shadow(color: Color.deltsAccent.opacity(0.45), radius: 9, y: 2)
                    }
                }
                .padding(.top, 6)

                Text("Loving the red button? Tell the App Store.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .multilineTextAlignment(.center)

                Button {
                    requestReview()
                    withAnimation(.snappy(duration: 0.25)) { didRequestReview = true }
                } label: {
                    Label(
                        didRequestReview ? "Thanks!" : "Rate Delts",
                        systemImage: didRequestReview ? "checkmark" : "star.fill"
                    )
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.deltsOnAccent)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 13)
                    .background(Color.deltsAccent, in: Capsule())
                    .shadow(color: Color.deltsAccent.opacity(0.35), radius: 12, y: 5)
                }
                .deltsPressable()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 18)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.deltsPanel.opacity(0.18))
                    .overlay {
                        RadialGradient(
                            colors: [Color.deltsAccent.opacity(0.10), .clear],
                            center: .top,
                            startRadius: 0,
                            endRadius: 240
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
            }

            Text("You can rate or review anytime from Settings → About.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func starSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [22, 27, 32, 27, 22]
        return sizes[index]
    }

    // MARK: - Terms

    private var termsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepHeader(icon: "checkmark.shield.fill", String(localized: "One last thing"), String(localized: "Review and accept to start using Delts."))

            VStack(spacing: 0) {
                termsLinkRow("hand.raised.fill", String(localized: "Privacy Policy"), "delts.fit/privacy") {
                    open("https://delts.fit/privacy")
                }
                cardDivider
                termsLinkRow("doc.text.fill", String(localized: "Terms"), "delts.fit/terms") {
                    open("https://delts.fit/terms")
                }
            }
            .padding(.vertical, 4)
            .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
            }

            Text("Delts is not medical advice — consult a professional before changing your training.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                withAnimation(.snappy(duration: 0.22)) { agreedToTerms.toggle() }
            } label: {
                HStack(spacing: 13) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(agreedToTerms ? Color.deltsAccent : Color.deltsPanel.opacity(0.42))
                            .frame(width: 27, height: 27)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.deltsHairline.opacity(agreedToTerms ? 0 : 0.55), lineWidth: 1)
                            }

                        if agreedToTerms {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(Color.deltsOnAccent)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Text("I agree to the Terms and Privacy Policy")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.deltsCharcoal)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(
                    agreedToTerms ? Color.deltsAccent.opacity(0.10) : Color.deltsPanel.opacity(0.18),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            agreedToTerms ? Color.deltsAccent.opacity(0.5) : Color.deltsHairline.opacity(0.3),
                            lineWidth: agreedToTerms ? 1 : 0.5
                        )
                }
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .deltsPressable()
            .accessibilityLabel("I agree to the Terms and Privacy Policy")
            .accessibilityValue(agreedToTerms ? "Agreed" : "Not agreed")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func termsLinkRow(_ systemImage: String, _ title: String, _ detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.deltsSecondaryAccent)
                    .frame(width: 34, height: 34)
                    .background(Color.deltsSecondaryAccent.opacity(0.10), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)

                Spacer(minLength: 8)

                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)

                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(Color.deltsMutedText.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .deltsPressable()
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if step == .terms && !agreedToTerms {
                Text("Tick the agreement above to continue")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .transition(.opacity)
            }

            PrimaryButton(
                title: primaryTitle,
                systemImage: primarySystemImage
            ) {
                advance()
            }
            .disabled(step == .terms && !agreedToTerms)
        }
        .animation(.snappy(duration: 0.2), value: agreedToTerms)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .deltsBottomActionBackground()
    }

    private var primaryTitle: String {
        switch step {
        case .welcome: return String(localized: "Get Started")
        case .terms: return String(localized: "Start Training")
        default: return String(localized: "Continue")
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        try? modelContext.save()
        goingForward = true
        withAnimation(.snappy(duration: 0.32)) {
            stepIndex = min(stepIndex + 1, steps.count - 1)
        }
    }

    private func goBack() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        goingForward = false
        withAnimation(.snappy(duration: 0.32)) {
            stepIndex = max(stepIndex - 1, 0)
        }
    }

    private func finish() {
        guard agreedToTerms else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        try? modelContext.save()
        termsAcceptedAt = Date().timeIntervalSince1970
        onboardingComplete = true
    }

    private func stepHeader(icon: String, _ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.deltsAccent)
                    .frame(width: 32, height: 32)
                    .background(Color.deltsAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text("Step \(stepIndex) of \(steps.count - 1)")
                    .font(.caption.weight(.heavy))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.deltsMutedText)
            }

            VStack(alignment: .leading, spacing: 6) {
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
