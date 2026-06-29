import Combine
import Foundation
import RevenueCat

/// RevenueCat-backed "Support Delts" tip jar. Tips are one-off (consumable)
/// purchases that unlock nothing — they simply support development. The whole
/// app stays free; this is purely optional.
@MainActor
final class TipStore: ObservableObject {
    static let shared = TipStore()

    /// RevenueCat public SDK key for the "Delts iOS" App Store app.
    static let revenueCatAPIKey = "appl_MruPsHFfCLYIQomGjxSWfYpiiqr"
    /// RevenueCat offering that holds the tip packages.
    static let tipsOfferingID = "tips"

    /// A single tip tier from the RevenueCat offering.
    struct Tip: Identifiable {
        let package: Package

        var id: String { package.identifier }
        var title: String { package.storeProduct.localizedTitle }
        var displayPrice: String { package.storeProduct.localizedPriceString }
        var price: Decimal { package.storeProduct.price }
    }

    @Published private(set) var tips: [Tip] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published var showThanks = false
    @Published var lastErrorMessage: String?

    private init() {
        Task { await loadTips() }
    }

    /// Loads the tip packages from the `tips` offering (falling back to the
    /// current offering), sorted cheapest first.
    func loadTips() async {
        guard tips.isEmpty, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let offerings = try await Purchases.shared.offerings()
            guard let offering = offerings.offering(identifier: Self.tipsOfferingID) ?? offerings.current else {
                return
            }
            tips = offering.availablePackages
                .map(Tip.init)
                .sorted { $0.price < $1.price }
        } catch {
            // Leave tips empty; the sheet shows its unavailable state.
        }
    }

    @discardableResult
    func purchase(_ tip: Tip) async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await Purchases.shared.purchase(package: tip.package)
            guard !result.userCancelled else { return false }
            showThanks = true
            return true
        } catch {
            let cancelled = (error as? RevenueCat.ErrorCode) == .purchaseCancelledError
            if !cancelled {
                lastErrorMessage = String(localized: "The tip couldn't be completed. Please try again.")
            }
            return false
        }
    }
}
