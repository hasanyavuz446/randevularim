import SwiftUI
import StoreKit

struct PaywallView: View {
    private let manager = SubscriptionManager.shared

    @State private var selectedPlan: PlanType = .yearly
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""

    enum PlanType { case monthly, yearly }

    private var selectedProduct: Product? {
        selectedPlan == .monthly ? manager.monthlyProduct : manager.yearlyProduct
    }

    private let features: [(String, String)] = [
        ("person.2.fill",           "Sınırsız müşteri ve randevu"),
        ("bell.badge.fill",         "Akıllı hatırlatma bildirimleri"),
        ("square.grid.2x2.fill",    "Ana ekran widget'ı"),
        ("arrow.counterclockwise",  "Yedekleme ve geri yükleme"),
        ("chart.bar.fill",          "Detaylı gelir raporları"),
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                        featuresSection
                    }
                }

                Spacer(minLength: 0)
                bottomSection
            }
        }
        .alert("Satın Alım Geri Yükleme", isPresented: $showRestoreAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
            }
            .padding(.top, 48)

            Text("Randevularım Pro")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.textPrimary)

            Text("14 gün ücretsiz deneyin, sonra dilediğiniz zaman iptal edin.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 32)
    }

    // MARK: Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(features, id: \.0) { icon, text in
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 26)
                    Text(text)
                        .font(.body)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }

    // MARK: Bottom

    private var bottomSection: some View {
        VStack(spacing: 14) {
            Divider()
                .background(AppTheme.divider)

            HStack(spacing: 12) {
                planCard(.monthly)
                planCard(.yearly)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            subscribeButton

            Text("Deneme sonrası otomatik ücretlendirme başlar. İstediğiniz zaman App Store üzerinden iptal edebilirsiniz.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 24)

            Button {
                Task { await restore() }
            } label: {
                Text("Satın Alımları Geri Yükle")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .disabled(manager.isPurchasing)

            HStack(spacing: 8) {
                Link("Gizlilik Politikası",
                     destination: URL(string: "https://hasanyavuz446.github.io/randevularim/privacy.html")!)
                Text("·")
                    .foregroundStyle(AppTheme.textSecondary)
                Link("Kullanım Koşulları",
                     destination: URL(string: "https://hasanyavuz446.github.io/randevularim/eula.html")!)
            }
            .font(.caption2)
            .foregroundStyle(AppTheme.primary)
            .padding(.bottom, 32)
        }
        .background(AppTheme.background)
    }

    // MARK: Plan Card

    @ViewBuilder
    private func planCard(_ plan: PlanType) -> some View {
        let isSelected = selectedPlan == plan
        let product  = plan == .monthly ? manager.monthlyProduct : manager.yearlyProduct
        let title    = plan == .monthly ? "Aylık" : "Yıllık"
        let price    = product?.displayPrice ?? (plan == .monthly ? "₺99" : "₺799")
        let period   = plan == .monthly ? "/ ay" : "/ yıl"

        Button { selectedPlan = plan } label: {
            VStack(spacing: 6) {
                if plan == .yearly {
                    Text("En Popüler")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.accent, in: Capsule())
                } else {
                    Spacer().frame(height: 19) // align heights
                }

                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)

                Text(price)
                    .font(.title3.bold())
                    .foregroundStyle(isSelected ? AppTheme.primary : AppTheme.textPrimary)

                Text(period)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? AppTheme.primary : Color.clear, lineWidth: 2)
            )
        }
    }

    // MARK: Subscribe Button

    private var subscribeButton: some View {
        Button {
            Task {
                guard let product = selectedProduct else { return }
                await manager.purchase(product)
            }
        } label: {
            HStack {
                if manager.isPurchasing {
                    ProgressView().tint(.white)
                } else if selectedProduct == nil {
                    ProgressView().tint(.white)
                } else {
                    Text("14 Gün Ücretsiz Başla")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(.white)
        }
        .disabled(manager.isPurchasing || selectedProduct == nil)
        .padding(.horizontal, 20)
    }

    // MARK: Restore

    private func restore() async {
        await manager.restore()
        if manager.status == .subscribed {
            restoreMessage = "Aboneliğiniz başarıyla geri yüklendi."
        } else {
            restoreMessage = "Aktif abonelik bulunamadı."
        }
        showRestoreAlert = true
    }
}
