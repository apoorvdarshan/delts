import Combine
import Foundation
import StoreKit

/// StoreKit 2 "Support Delts" tip jar. Tips are one-off consumable purchases
/// that unlock nothing — they simply support development. The whole app stays
/// free; this is purely optional. No RevenueCat, no backend.
@MainActor
final class TipStore: ObservableObject {
    static let shared = TipStore()

    static let productIDs = [
        "com.apoorvdarshan.delts.tip.small",
        "com.apoorvdarshan.delts.tip.medium",
        "com.apoorvdarshan.delts.tip.large"
    ]

    @Published private(set) var tips: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published var showThanks = false
    @Published var lastErrorMessage: String?

    private init() {
        Task { await loadTips() }
    }

    func loadTips() async {
        guard tips.isEmpty, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: Self.productIDs)
            tips = products.sorted { $0.price < $1.price }
        } catch {
            // Leave tips empty; the sheet shows its unavailable state.
        }
    }

    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case let .success(verification):
                if case let .verified(transaction) = verification {
                    // Consumable tip: finish immediately, nothing to unlock.
                    await transaction.finish()
                    showThanks = true
                    return true
                }
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = String(localized: "The tip couldn't be completed. Please try again.")
            return false
        }
    }
}
