import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \Business.name) private var businesses: [Business]
    @Query(sort: \Service.sortOrder) private var services: [Service]

    private var business: Business {
        businesses.first ?? Business.defaultBusiness()
    }

    var body: some View {
        RandevularimScreen(title: "Ayarlar") {
            List {
                Section("İşletme") {
                    LabeledContent("Ad", value: business.name)
                    LabeledContent("Kategori", value: business.category)
                    LabeledContent("Çalışma saatleri", value: "\(business.openingTime) - \(business.closingTime)")
                }

                Section("Hizmetler") {
                    ForEach(services) { service in
                        HStack {
                            Circle()
                                .fill(service.color)
                                .frame(width: 12, height: 12)
                            Text(service.name)
                            Spacer()
                            Text("\(service.durationMinutes) dk")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }

                Section("Native iOS") {
                    Label("Live Activities hazırlığı", systemImage: "waveform.path.ecg")
                    Label("WidgetKit hazırlığı", systemImage: "rectangle.grid.2x2")
                    Label("Siri/App Intents hazırlığı", systemImage: "sparkles")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
        }
    }
}
