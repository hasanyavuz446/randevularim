import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        RandevularimScreen(title: "Ayarlar") {
            List {
                Section("İşletme") {
                    LabeledContent("Ad", value: store.business.name)
                    LabeledContent("Kategori", value: store.business.category)
                    LabeledContent("Çalışma saatleri", value: "\(store.business.openingTime) - \(store.business.closingTime)")
                }

                Section("Hizmetler") {
                    ForEach(store.services) { service in
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
