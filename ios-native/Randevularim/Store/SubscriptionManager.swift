import Foundation
import StoreKit

@Observable final class SubscriptionManager {
    static let shared = SubscriptionManager()

    enum Status: Equatable {
        case loading
        case trial(daysLeft: Int)
        case subscribed
        case expired
    }

    private(set) var status: Status = .loading
    private(set) var products: [Product] = []
    private(set) var isPurchasing = false
    private(set) var purchaseError: String?

    static let monthlyId = "com.hasanyavuz.randevularim.subscription.monthly"
    static let yearlyId  = "com.hasanyavuz.randevularim.subscription.yearly"
    private static let trialDays = 14
    private static let firstLaunchKey = "subscription.firstLaunchDate"

    // Access is granted while loading (status resolves in <1s) or during trial/subscription.
    var isAccessGranted: Bool {
        switch status {
        case .loading, .trial, .subscribed: return true
        case .expired: return false
        }
    }

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyId } }
    var yearlyProduct:  Product? { products.first { $0.id == Self.yearlyId  } }

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        recordFirstLaunchIfNeeded()
        updateListenerTask = listenForTransactions()
    }

    deinit { updateListenerTask?.cancel() }

    func initialize() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadProducts() }
            group.addTask { await self.refreshStatus() }
        }
    }

    private func recordFirstLaunchIfNeeded() {
        guard UserDefaults.standard.object(forKey: Self.firstLaunchKey) == nil else { return }
        UserDefaults.standard.set(Date.now, forKey: Self.firstLaunchKey)
    }

    private var trialDaysLeft: Int {
        guard let first = UserDefaults.standard.object(forKey: Self.firstLaunchKey) as? Date else {
            return Self.trialDays
        }
        let passed = Calendar.current.dateComponents([.day], from: first, to: .now).day ?? 0
        return max(0, Self.trialDays - passed)
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
        let daysLeft = trialDaysLeft
        status = daysLeft > 0 ? .trial(daysLeft: daysLeft) : .expired
    }

    private func loadProducts() async {
        do {
            let fetched = try await Product.products(for: [Self.monthlyId, Self.yearlyId])
            await MainActor.run {
                products = fetched.sorted { $0.price < $1.price }
            }
        } catch {
            // Fiyatlar fallback string'lerden gösterilir
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
