import StoreKit
import Foundation

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    @Published var products: [Product] = []
    @Published var isPremium: Bool = false
    @Published var statusText: String = "Checking…"

    private let productIDs = ["lamp.premium.monthly", "lamp.premium.yearly"]

    func load() async {
        do {
            products = try await Product.products(for: productIDs).sorted { $0.price < $1.price }
            await refreshEntitlements()
            for await _ in Transaction.updates {
                await refreshEntitlements()
            }
        } catch {
            statusText = "Store unavailable"
        }
    }

    func buy(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                _ = try checkVerified(verification)
                await refreshEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default: break
            }
        } catch { }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch { }
    }

    private func refreshEntitlements() async {
        var premiumActive = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let t) = entitlement, t.productType == .autoRenewable, productIDs.contains(t.productID) {
                premiumActive = true
                break
            }
        }
        isPremium = premiumActive
        statusText = premiumActive ? "Premium active" : "Free"
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "IAP", code: 1, userInfo: [NSLocalizedDescriptionKey: "Transaction unverified"])
        case .verified(let safe):
            return safe
        }
    }
} 