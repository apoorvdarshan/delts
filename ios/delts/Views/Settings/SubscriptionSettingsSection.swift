import StoreKit
import SwiftUI

/// Settings section for Delts Premium: plan status, manage, restore, upgrade.
struct SubscriptionSettingsSection: View {
    @ObservedObject private var premium = PremiumStore.shared
    @State private var showManageSubscriptions = false
    @State private var showPaywall = false
    @State private var isRestoring = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subscription")
                .font(.callout.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
                .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 0) {
                statusRow
                divider

                if !premium.isSubscribed {
                    actionRow(
                        title: String(localized: "Get Delts Premium"),
                        systemImage: "sparkles",
                        value: String(localized: "Unlock AI"),
                        tint: .deltsAccent
                    ) {
                        showPaywall = true
                    }
                    divider
                }

                actionRow(
                    title: String(localized: "Manage Subscription"),
                    systemImage: "creditcard.fill",
                    value: String(localized: "App Store"),
                    tint: .deltsSecondaryAccent
                ) {
                    showManageSubscriptions = true
                }
                divider
                actionRow(
                    title: "Restore Purchases",
                    systemImage: "arrow.clockwise.circle.fill",
                    value: isRestoring ? String(localized: "Restoring…") : "",
                    tint: .deltsSecondaryAccent
                ) {
                    restore()
                }
            }
            .padding(.horizontal, 14)
            .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.22), lineWidth: 0.5)
            }

            Text("Subscriptions auto-renew until cancelled. Manage or cancel anytime in your App Store account settings.")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.top, 2)
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert(
            "Restore Purchases",
            isPresented: Binding(
                get: { premium.lastErrorMessage != nil },
                set: { if !$0 { premium.lastErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { premium.lastErrorMessage = nil }
        } message: {
            Text(premium.lastErrorMessage ?? "")
        }
    }

    // MARK: - Rows

    private var statusRow: some View {
        HStack(alignment: .center, spacing: 11) {
            Image(systemName: premium.isSubscribed ? "checkmark.seal.fill" : "lock.fill")
                .font(.system(size: 19, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(premium.isSubscribed ? Color.deltsAccent : Color.deltsMutedText)
                .frame(width: 38, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("Delts Premium")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)

                if let detail = statusDetail {
                    Text(detail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                }
            }

            Spacer(minLength: 12)

            Text(premium.isSubscribed ? "Active" : "Not Active")
                .font(.body.weight(.semibold))
                .foregroundStyle(premium.isSubscribed ? Color.deltsAccent : Color.deltsMutedText)
        }
        .padding(.vertical, 9)
    }

    private var statusDetail: String? {
        guard premium.isSubscribed else {
            return String(localized: "AI Coach and calorie estimates are locked")
        }
        var parts: [String] = []
        if let plan = premium.activePlanTitle {
            parts.append(plan)
        }
        if let date = premium.expiresAt {
            let formatted = date.formatted(date: .abbreviated, time: .omitted)
            parts.append(premium.willRenew ? String(localized: "renews \(formatted)") : String(localized: "expires \(formatted)"))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func actionRow(
        title: String,
        systemImage: String,
        value: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
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

                Spacer(minLength: 12)

                HStack(spacing: 7) {
                    if !value.isEmpty {
                        Text(value)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.deltsMutedText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText.opacity(0.72))
                }
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .deltsPressable()
        .disabled(isRestoring && title == "Restore Purchases")
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.28))
            .frame(height: 0.5)
            .padding(.leading, 48)
    }

    // MARK: - Actions

    private func restore() {
        guard !isRestoring else { return }
        isRestoring = true
        Task {
            await PremiumStore.shared.restorePurchases()
            isRestoring = false
        }
    }
}
