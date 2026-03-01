import Foundation
import StoreKit

// MARK: - ProStatusCache

private enum ProStatusCache {
    private static let activeKey    = AppConfig.Keys.proCachedActive
    private static let checkedAtKey = AppConfig.Keys.proCachedCheckedAt
    private static let cacheTTL: TimeInterval = 7 * 24 * 60 * 60

    static func getValidCachedState() -> Bool {
        guard
            let checkedAt = UserDefaults.standard.object(forKey: checkedAtKey) as? Date,
            Date().timeIntervalSince(checkedAt) < cacheTTL
        else { return false }
        return UserDefaults.standard.bool(forKey: activeKey)
    }

    static func update(active: Bool) {
        UserDefaults.standard.set(active,  forKey: activeKey)
        UserDefaults.standard.set(Date(),  forKey: checkedAtKey)
    }
}

// MARK: - IAPManager

@MainActor
final class IAPManager: ObservableObject {
    static let shared = IAPManager()

    static let productID = AppConfig.iapProductID

    @Published private(set) var isPurchased: Bool = false
    @Published private(set) var product: Product? = nil
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var transactionListener: Task<Void, Never>? = nil

    private init() {
        isPurchased = ProStatusCache.getValidCachedState()
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        await loadProductsWithRetry(maxAttempts: 3)
        await refreshOnceOnLaunch()
    }

    private func loadProductsWithRetry(maxAttempts: Int) async {
        var delay: UInt64 = 1_000_000_000
        for attempt in 1...maxAttempts {
            do {
                let products = try await Product.products(for: [Self.productID])
                if let first = products.first {
                    product = first
                    return
                }
            } catch {
                if attempt == maxAttempts { return }
                try? await Task.sleep(nanoseconds: delay)
                delay *= 2
            }
        }
    }

    func purchaseUnlock() async -> Bool {
        if product == nil {
            await loadProductsWithRetry(maxAttempts: 2)
        }
        guard let product else {
            errorMessage = "商品情報が読み込まれていません。ネットワーク接続を確認してください"
            return false
        }
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await apply(active: true)
                await refreshNow()
                return true
            case .pending:
                errorMessage = "購入が保留中です。審査完了後に有効になります"
                return false
            case .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "購入処理中にエラーが発生しました"
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshNow()
        } catch {
            errorMessage = "復元処理中にエラーが発生しました"
        }
    }

    func refreshNow() async {
        var sawAnyResult = false
        var active = false

        for await result in Transaction.currentEntitlements {
            sawAnyResult = true
            if case .verified(let tx) = result, tx.productID == Self.productID {
                active = true
            }
        }

        guard sawAnyResult else { return }
        await apply(active: active)
    }

    private func refreshOnceOnLaunch() async {
        await refreshNow()
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                if case .verified(let tx) = result {
                    await tx.finish()
                    if tx.productID == Self.productID {
                        let active = tx.revocationDate == nil
                        await self.apply(active: active)
                    }
                }
            }
        }
    }

    private func apply(active: Bool) async {
        isPurchased = active
        ProStatusCache.update(active: active)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    func debugSetPurchased(_ value: Bool) {
        isPurchased = value
        ProStatusCache.update(active: value)
    }
}

private enum StoreError: Error {
    case failedVerification
}
