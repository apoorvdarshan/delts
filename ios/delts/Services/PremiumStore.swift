import Combine
import Foundation
import StoreKit

/// StoreKit 2 subscription manager for Delts Premium, plus the one-time
/// lifetime "taste" allowance that lets new users try the AI features
/// (Coach chat + calorie estimates) before subscribing.
///
/// Free tier = every local feature (timer, logging, history, progress).
/// Premium  = hosted AI: Coach chat and calorie-burn estimates.
@MainActor
final class PremiumStore: ObservableObject {
    static let shared = PremiumStore()

    enum ProductID {
        static let weekly = "delts.premium.weekly"
        static let yearly = "delts.premium.yearly"
        static let all: Set<String> = [weekly, yearly]
    }

    /// One-time lifetime allowances (not monthly) so the taste can't be
    /// farmed as a permanent free tier.
    static let coachTasteLimit = 5
    static let calorieTasteLimit = 3

    @Published private(set) var products: [Product] = []
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
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refreshEntitlement()
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

    func refreshEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if ProductID.all.contains(transaction.productID), transaction.revocationDate == nil {
                active = true
            }
        }
        isSubscribed = active
    }

    // MARK: - Products

    var weeklyProduct: Product? { products.first { $0.id == ProductID.weekly } }
    var yearlyProduct: Product? { products.first { $0.id == ProductID.yearly } }

    func loadProducts() async {
        guard products.isEmpty, !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: ProductID.all)
        } catch {
            products = []
        }
    }

    // MARK: - Purchase / restore

    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                } else {
                    lastErrorMessage = "The purchase could not be verified. You have not been charged twice — try Restore Purchases."
                }
                await refreshEntitlement()
                return isSubscribed
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = "The purchase could not be completed. Check your connection and try again."
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            lastErrorMessage = "Restore failed. Check your connection and try again."
            return
        }
        await refreshEntitlement()
        if !isSubscribed {
            lastErrorMessage = "No active subscription was found for this Apple ID."
        }
    }
}
