import Combine
import Foundation
import RevenueCat

/// Subscription manager for Delts Premium, backed by RevenueCat (which uses
/// StoreKit 2 under the hood and verifies receipts server-side).
///
/// Free tier = every local feature (timer, logging, history, progress).
/// Premium  = hosted AI: Coach chat and calorie-burn estimates. There is no
/// free AI allowance — AI features are locked until a subscription is active.
@MainActor
final class PremiumStore: ObservableObject {
    static let shared = PremiumStore()

    /// RevenueCat public SDK key for the "Delts iOS" App Store app.
    static let revenueCatAPIKey = "appl_MruPsHFfCLYIQomGjxSWfYpiiqr"
    /// RevenueCat entitlement that gates the AI features.
    static let entitlementID = "premium"

    /// A purchasable plan from the current RevenueCat offering.
    struct Plan {
        let package: Package

        var displayPrice: String { package.storeProduct.localizedPriceString }
        var price: Decimal { package.storeProduct.price }
    }

    @Published private(set) var weeklyPlan: Plan?
    @Published private(set) var yearlyPlan: Plan?
    @Published private(set) var isSubscribed = false
    @Published private(set) var activeProductID: String?
    @Published private(set) var expiresAt: Date?
    @Published private(set) var willRenew = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published var lastErrorMessage: String?

    /// User-facing name of the active plan, e.g. "Yearly".
    var activePlanTitle: String? {
        guard let activeProductID else { return nil }
        if activeProductID.contains("yearly") { return String(localized: "Yearly") }
        if activeProductID.contains("weekly") { return String(localized: "Weekly") }
        return String(localized: "Premium")
    }

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.apply(info)
            }
        }
        Task {
            await refreshEntitlement()
            await loadProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Entitlement

    var canUseCoach: Bool { isSubscribed }
    var canEstimateCalories: Bool { isSubscribed }

    /// RevenueCat App User ID for this install (anonymous unless logged in).
    /// Used to identify this customer in the RevenueCat dashboard, e.g. to grant
    /// a promotional entitlement.
    var appUserID: String { Purchases.shared.appUserID }

    private func apply(_ info: CustomerInfo) {
        let entitlement = info.entitlements[Self.entitlementID]
            ?? info.entitlements.active.values.first
        let active = entitlement?.isActive == true
        isSubscribed = active
        activeProductID = active ? entitlement?.productIdentifier : nil
        expiresAt = active ? entitlement?.expirationDate : nil
        willRenew = active ? (entitlement?.willRenew ?? false) : false
    }

    func refreshEntitlement() async {
        if let info = try? await Purchases.shared.customerInfo() {
            apply(info)
        }
    }

    // MARK: - Products

    func loadProducts() async {
        guard weeklyPlan == nil || yearlyPlan == nil, !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let current = offerings.current else { return }
            yearlyPlan = (current.annual ?? current.package(identifier: "$rc_annual")).map(Plan.init)
            weeklyPlan = (current.weekly ?? current.package(identifier: "$rc_weekly")).map(Plan.init)
        } catch {
            // Leave plans nil; the paywall shows its unavailable state.
        }
    }

    // MARK: - Purchase / restore

    @discardableResult
    func purchase(_ plan: Plan) async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await Purchases.shared.purchase(package: plan.package)
            apply(result.customerInfo)
            return isSubscribed
        } catch {
            let cancelled = (error as? RevenueCat.ErrorCode) == .purchaseCancelledError
            if !cancelled {
                lastErrorMessage = String(localized: "The purchase could not be completed. Check your connection and try again.")
            }
            return false
        }
    }

    func restorePurchases() async {
        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            if !isSubscribed {
                lastErrorMessage = String(localized: "No active subscription was found for this Apple ID.")
            }
        } catch {
            lastErrorMessage = String(localized: "Restore failed. Check your connection and try again.")
        }
    }
}
