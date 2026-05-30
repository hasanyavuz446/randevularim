import Foundation
import StoreKit

@Observable final class SubscriptionManager {
    static let shared = SubscriptionManager()

    enum Status: Equatable {
        case loading
        case subscribed
        case expired
    }

    private(set) var status: Status = .loading
    private(set) var products: [Product] = []
    private(set) var isPurchasing = false
    private(set) var purchaseError: String?
    private(set) var productsLoadFailed = false

    static let monthlyId = "com.hasanyavuz.randevularim.subscription.monthly"
    static let yearlyId  = "com.hasanyavuz.randevularim.subscription.yearly"

    var isAccessGranted: Bool {
        status == .subscribed || BuildEnvironment.allowsLocalSubscriptionBypass
    }

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyId } }
    var yearlyProduct:  Product? { products.first { $0.id == Self.yearlyId  } }

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
    }

    deinit { updateListenerTask?.cancel() }

    func initialize() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadProducts() }
            group.addTask { await self.refreshStatus() }
        }
    }

    @MainActor
    func refreshStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               (tx.productID == Self.monthlyId || tx.productID == Self.yearlyId),
               tx.revocationDate == nil {
                status = .subscribed
                return
            }
        }
        status = .expired
    }

    @MainActor
    func retryLoadProducts() async {
        productsLoadFailed = false
        await loadProducts()
    }

    private func loadProducts() async {
        do {
            let fetched = try await Product.products(for: [Self.monthlyId, Self.yearlyId])
            await MainActor.run {
                products = fetched.sorted { $0.price < $1.price }
                productsLoadFailed = fetched.isEmpty
            }
        } catch {
            await MainActor.run { productsLoadFailed = true }
        }
    }

    @MainActor
    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    await tx.finish()
                    await refreshStatus()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    @MainActor
    func restore() async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshStatus()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await tx.finish()
                    await self?.refreshStatus()
                }
            }
        }
    }
}

enum BuildEnvironment {
    static var allowsLocalSubscriptionBypass: Bool {
        #if DEBUG
        return true
        #else
        return Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision") != nil
        #endif
    }
}
