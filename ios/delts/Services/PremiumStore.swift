import Combine
import Foundation
import RevenueCat

/// Subscription manager for Delts Premium, backed by RevenueCat (which uses
/// StoreKit 2 under the hood and verifies receipts server-side), plus the
/// one-time lifetime "taste" allowance that lets new users try the AI features
/// (Coach chat + calorie estimates) before subscribing.
///
/// Free tier = every local feature (timer, logging, history, progress).
/// Premium  = hosted AI: Coach chat and calorie-burn estimates.
@MainActor
final class PremiumStore: ObservableObject {
    static let shared = PremiumStore()

    /// RevenueCat public SDK key for the "Delts iOS" App Store app.
    static let revenueCatAPIKey = "appl_MruPsHFfCLYIQomGjxSWfYpiiqr"
    /// RevenueCat entitlement that gates the AI features.
    static let entitlementID = "premium"

    /// One-time lifetime allowances (not monthly) so the taste can't be
    /// farmed as a permanent free tier.
    static let coachTasteLimit = 5
    static let calorieTasteLimit = 3

    /// A purchasable plan from the current RevenueCat offering.
    struct Plan {
        let package: Package

        var displayPrice: String { package.storeProduct.localizedPriceString }
        var price: Decimal { package.storeProduct.price }
    }

    @Published private(set) var weeklyPlan: Plan?
    @Published private(set) var yearlyPlan: Plan?
    @Published private(set) var isSubscribed = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published var lastErrorMessage: String?
    @Published private(set) var coachTasteUsed: Int
    @Published private(set) var calorieTasteUsed: Int

    private var updatesTask: Task<Void, Never>?

    private init() {
        coachTasteUsed = UserDefaults.standard.integer(forKey: "delts_taste_coach_used")
        calorieTasteUsed = UserDefaults.standard.integer(forKey: "delts_taste_calorie_used")
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

    var coachTasteRemaining: Int { max(0, Self.coachTasteLimit - coachTasteUsed) }
    var calorieTasteRemaining: Int { max(0, Self.calorieTasteLimit - calorieTasteUsed) }

    var canUseCoach: Bool { isSubscribed || coachTasteRemaining > 0 }
    var canEstimateCalories: Bool { isSubscribed || calorieTasteRemaining > 0 }

    func consumeCoachTaste() {
        guard !isSubscribed else { return }
        coachTasteUsed += 1
        UserDefaults.standard.set(coachTasteUsed, forKey: "delts_taste_coach_used")
    }

    func consumeCalorieTaste() {
        guard !isSubscribed else { return }
        calorieTasteUsed += 1
        UserDefaults.standard.set(calorieTasteUsed, forKey: "delts_taste_calorie_used")
    }

    private func apply(_ info: CustomerInfo) {
        isSubscribed = info.entitlements[Self.entitlementID]?.isActive == true
            || !info.entitlements.active.isEmpty
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
                lastErrorMessage = "The purchase could not be completed. Check your connection and try again."
            }
            return false
        }
    }

    func restorePurchases() async {
        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            if !isSubscribed {
                lastErrorMessage = "No active subscription was found for this Apple ID."
            }
        } catch {
            lastErrorMessage = "Restore failed. Check your connection and try again."
        }
    }
}
