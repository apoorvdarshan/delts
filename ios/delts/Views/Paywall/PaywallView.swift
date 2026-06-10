import StoreKit
import SwiftUI

/// Delts Premium paywall. Free tier keeps every local feature; Premium unlocks
/// the hosted AI features (Coach chat + calorie-burn estimates).
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var store = PremiumStore.shared

    @State private var selectedPlan: Plan = .yearly
    @State private var isRestoring = false

    private enum Plan {
        case weekly
        case yearly
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 22) {
                    hero
                    featureList
                    planPicker
                    if !productsAvailable && !store.isLoadingProducts {
                        Text("Subscriptions aren't available right now. Try again later.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.deltsMutedText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 18)
            }

            footer
        }
        .deltsScreen()
        .background(alignment: .top) {
            RadialGradient(
                colors: [Color.deltsAccent.opacity(0.14), .clear],
                center: .top,
                startRadius: 10,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
        .task { await store.loadProducts() }
        .onChange(of: store.isSubscribed) { _, subscribed in
            if subscribed { dismiss() }
        }
        .alert(
            "Something Went Wrong",
            isPresented: Binding(
                get: { store.lastErrorMessage != nil },
                set: { if !$0 { store.lastErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { store.lastErrorMessage = nil }
        } message: {
            Text(store.lastErrorMessage ?? "")
        }
    }

    private var productsAvailable: Bool {
        store.weeklyProduct != nil || store.yearlyProduct != nil
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .frame(width: 32, height: 32)
                    .background(Color.deltsPanel.opacity(0.32), in: Circle())
            }
            .deltsPressable()
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 12) {
            Image("DeltsGlyph")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)

            Text("DELTS PREMIUM")
                .font(.caption.weight(.heavy))
                .tracking(2.4)
                .foregroundStyle(Color.deltsAccent)

            Text("Train with the AI Coach")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.deltsCharcoal)
                .multilineTextAlignment(.center)

            Text("Everything local stays free. Premium unlocks the AI that knows your training.")
                .font(.subheadline)
                .foregroundStyle(Color.deltsMutedText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(spacing: 0) {
            featureRow("bubble.left.and.text.bubble.right.fill", "Unlimited AI Coach", "Chat about training, form, and nutrition — it sees your real data")
            divider
            featureRow("photo.fill", "Photo analysis", "Send gym equipment, meals, or physique photos to the Coach")
            divider
            featureRow("flame.fill", "Calorie burn estimates", "Automatic kcal after every session, synced to Apple Health")
            divider
            featureRow("chart.line.uptrend.xyaxis", "Burn in your History", "Every logged workout gets its energy filled in")
        }
        .padding(.vertical, 6)
        .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.22))
            .frame(height: 0.5)
            .padding(.leading, 64)
    }

    private func featureRow(_ systemImage: String, _ title: String, _ subtitle: String) -> some View {
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
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Plans

    private var planPicker: some View {
        VStack(spacing: 12) {
            planCard(
                plan: .yearly,
                title: "Yearly",
                price: store.yearlyProduct?.displayPrice ?? "$39.99",
                caption: yearlyCaption,
                badge: "BEST VALUE"
            )
            planCard(
                plan: .weekly,
                title: "Weekly",
                price: store.weeklyProduct?.displayPrice ?? "$1.99",
                caption: "per week · cancel anytime",
                badge: nil
            )
        }
    }

    private var yearlyCaption: String {
        guard let yearly = store.yearlyProduct, let weekly = store.weeklyProduct else {
            return "per year · save over 60%"
        }
        let weeklyPerYear = weekly.price * 52
        guard weeklyPerYear > 0 else { return "per year" }
        let savings = (1 - (yearly.price / weeklyPerYear)) * 100
        let rounded = NSDecimalNumber(decimal: savings).intValue
        return rounded > 0 ? "per year · save \(rounded)% vs weekly" : "per year"
    }

    private func planCard(plan: Plan, title: String, price: String, caption: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            withAnimation(.snappy(duration: 0.2)) { selectedPlan = plan }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsMutedText.opacity(0.5))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.deltsCharcoal)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .heavy))
                                .tracking(0.8)
                                .foregroundStyle(Color.deltsOnAccent)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.deltsAccent, in: Capsule())
                        }
                    }

                    Text(caption)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                }

                Spacer(minLength: 8)

                Text(price)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                isSelected ? Color.deltsAccent.opacity(0.10) : Color.deltsPanel.opacity(0.18),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? Color.deltsAccent.opacity(0.55) : Color.deltsHairline.opacity(0.3),
                        lineWidth: isSelected ? 1.2 : 0.5
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .deltsPressable()
        .accessibilityLabel("\(title), \(price), \(caption)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 10) {
            PrimaryButton(
                title: store.isPurchasing ? "Processing" : "Continue",
                systemImage: "lock.open.fill",
                isLoading: store.isPurchasing
            ) {
                purchaseSelected()
            }
            .disabled(!productsAvailable || store.isPurchasing)

            Text("Auto-renews until cancelled. Cancel anytime in Settings.")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)

            HStack(spacing: 18) {
                Button("Restore Purchases") {
                    restore()
                }
                .disabled(isRestoring)

                Button("Terms") { open("https://delts.fit/terms") }
                Button("Privacy") { open("https://delts.fit/privacy") }
            }
            .font(.caption.weight(.bold))
            .tint(Color.deltsSecondaryAccent)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .deltsBottomActionBackground()
    }

    // MARK: - Actions

    private func purchaseSelected() {
        let product = selectedPlan == .yearly ? store.yearlyProduct : store.weeklyProduct
        guard let product else { return }
        Task {
            await PremiumStore.shared.purchase(product)
        }
    }

    private func restore() {
        isRestoring = true
        Task {
            await PremiumStore.shared.restorePurchases()
            isRestoring = false
        }
    }

    private func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        openURL(url)
    }
}
