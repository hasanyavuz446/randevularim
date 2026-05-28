import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Contacts

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var systemColorScheme
    @Query(sort: \Business.name) private var businesses: [Business]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("globalNotificationsEnabled") private var globalNotificationsEnabled = true
    @AppStorage("defaultReminderMinutes") private var defaultReminderMinutes = 30
    @AppStorage("selectedThemeId") private var selectedThemeId = "night_blue"
    @AppStorage("colorSchemePref") private var colorSchemePref = "dark"
    @State private var isShowingBusinessForm = false
    @State private var exportDocument: BackupDocument?
    @State private var isShowingExporter = false
    @State private var isShowingImporter = false
    @State private var statusMessage: String?
    @State private var isShowingContactPicker = false
    @State private var isShowingResetConfirm = false
    @State private var isShowingDeleteCustomersConfirm = false
    @State private var isShowingDeletePastAppointmentsConfirm = false

    private var business: Business { businesses.first ?? Business.defaultBusiness() }

    var body: some View {
        RandevularimScreen(title: "Ayarlar") {
            List {
                Section("Görünüm") {
                    AppearancePicker(selected: colorSchemePref) { newValue in
                        colorSchemePref = newValue
                        applyTheme(id: selectedThemeId, colorSchemePref: newValue)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(ThemeConfig.all, id: \.id) { config in
                            ThemeSwatch(
                                config: config,
                                isSelected: selectedThemeId == config.id
                            ) {
                                selectedThemeId = config.id
                                applyTheme(id: config.id, colorSchemePref: colorSchemePref)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 12, trailing: 12))
                }

                Section("İşletme") {
                    LabeledContent("Ad", value: business.name)
                    LabeledContent("Kategori", value: business.category)
                    LabeledContent("Çalışma saatleri", value: "\(business.openingTime) - \(business.closingTime)")
                    Button("İşletmeyi Düzenle") { isShowingBusinessForm = true }
                }

                Section("Hizmetler") {
                    NavigationLink("Hizmetleri Düzenle") {
                        ServiceManagementView()
                    }
                }

                Section("Yedek") {
                    Button("JSON Yedek Al") {
                        do {
                            exportDocument = BackupDocument(data: try BackupService.exportData(from: modelContext))
                            isShowingExporter = true
                        } catch {
                            statusMessage = "Yedek alınamadı: \(error.localizedDescription)"
                        }
                    }
                    Button("Yedekten Geri Yükle") { isShowingImporter = true }
                }

                Section("Rehber") {
                    Button("Rehberden Müşteri Aktar") {
                        isShowingContactPicker = true
                    }
                }

                Section("Bildirimler") {
                    Toggle(isOn: $globalNotificationsEnabled) {
                        Label("Genel Bildirimler", systemImage: "bell.fill")
                    }
                    if globalNotificationsEnabled {
                        Picker(selection: $defaultReminderMinutes) {
                            Text("Tam zamanında").tag(0)
                            Text("15 dk önce").tag(15)
                            Text("30 dk önce").tag(30)
                            Text("45 dk önce").tag(45)
                            Text("1 sa önce").tag(60)
                            Text("2 sa önce").tag(120)
                        } label: {
                            Label("Varsayılan Hatırlatma", systemImage: "timer")
                        }
                    }
                }

                Section("İlk Açılış") {
                    Button("Onboarding'i Tekrar Göster") { hasCompletedOnboarding = false }
                }

                Section("Takvim") {
                    if CalendarSyncService.shared.isEnabled {
                        Button("Takvim Senkronizasyonunu Kaldır", role: .destructive) {
                            CalendarSyncService.shared.removeAll()
                            statusMessage = "Takvim senkronizasyonu kaldırıldı."
                        }
                    } else {
                        Text("Takvim senkronizasyonu kapalı. Takvim ekranındaki takvim ikonuna basarak başlatabilirsiniz.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Section("Sıfırlama") {
                    Button("Kayıtlı Tüm Müşterileri Sil", role: .destructive) {
                        isShowingDeleteCustomersConfirm = true
                    }

                    Button("Geçmiş Tüm Randevuları Sil", role: .destructive) {
                        isShowingDeletePastAppointmentsConfirm = true
                    }

                    Button("Tüm Verileri Sıfırla", role: .destructive) {
                        isShowingResetConfirm = true
                    }
                }

                Section {
                    HStack {
                        Text("Sürüm")
                        Spacer()
                        Text(appVersionString)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage).foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .sheet(isPresented: $isShowingBusinessForm) {
                BusinessFormView(business: business)
            }
            .fileExporter(
                isPresented: $isShowingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "randevularim-yedek"
            ) { result in
                switch result {
                case .success: statusMessage = "Yedek dışa aktarıldı."
                case .failure(let error): statusMessage = "Yedek dışa aktarılamadı: \(error.localizedDescription)"
                }
            }
            .fileImporter(isPresented: $isShowingImporter, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    guard url.startAccessingSecurityScopedResource() else {
                        statusMessage = "Dosya erişimi alınamadı."
                        return
                    }
                    defer { url.stopAccessingSecurityScopedResource() }
                    try BackupService.restoreData(Data(contentsOf: url), into: modelContext)
                    statusMessage = "Yedek geri yüklendi."
                } catch {
                    statusMessage = "Yedek geri yüklenemedi: \(error.localizedDescription)"
                }
            }
            .alert("Tüm Verileri Sıfırla", isPresented: $isShowingResetConfirm) {
                Button("Sıfırla", role: .destructive) {
                    do {
                        try SeedDataService.resetAllData(in: modelContext)
                        statusMessage = "Tüm veriler silindi. İşletme ve hizmetler varsayılana döndürüldü."
                    } catch {
                        statusMessage = "Sıfırlama başarısız: \(error.localizedDescription)"
                    }
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Tüm müşteriler, randevular ve özel hizmetler silinir. İşletme bilgileri ve varsayılan hizmetler yeniden oluşturulur. Bu işlem geri alınamaz.")
            }
            .alert("Kayıtlı Tüm Müşterileri Sil", isPresented: $isShowingDeleteCustomersConfirm) {
                Button("Müşterileri Sil", role: .destructive) {
                    do {
                        let count = try SeedDataService.deleteAllCustomers(in: modelContext)
                        statusMessage = "\(count) müşteri ve bağlı randevuları silindi."
                    } catch {
                        statusMessage = "Müşteriler silinemedi: \(error.localizedDescription)"
                    }
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Kayıtlı tüm müşteriler ve bu müşterilere bağlı randevular silinir. Hizmetler ve işletme ayarları korunur. Bu işlem geri alınamaz.")
            }
            .alert("Geçmiş Tüm Randevuları Sil", isPresented: $isShowingDeletePastAppointmentsConfirm) {
                Button("Geçmiş Randevuları Sil", role: .destructive) {
                    do {
                        let count = try SeedDataService.deletePastAppointments(in: modelContext)
                        statusMessage = "\(count) geçmiş randevu silindi."
                    } catch {
                        statusMessage = "Geçmiş randevular silinemedi: \(error.localizedDescription)"
                    }
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Bugünden önceki randevular silinir. Bugünkü ve gelecek randevular korunur. Bu işlem geri alınamaz.")
            }
            .sheet(isPresented: $isShowingContactPicker) {
                ContactPickerSheet { count in
                    statusMessage = "\(count) yeni müşteri aktarıldı."
                }
            }
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }

    private func applyTheme(id: String, colorSchemePref: String) {
        AppTheme.apply(
            id: id,
            colorSchemePref: colorSchemePref,
            systemColorScheme: systemColorScheme
        )
    }

}

// MARK: - Appearance

private struct AppearancePicker: View {
    let selected: String
    let onSelect: (String) -> Void

    private let options = [
        ("light", "sun.max.fill", "Açık"),
        ("dark", "moon.stars.fill", "Koyu"),
        ("auto", "circle.lefthalf.filled", "Otomatik")
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.0) { option in
                let isSelected = selected == option.0
                Button {
                    onSelect(option.0)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: option.1)
                            .font(.system(size: 18, weight: .semibold))
                        Text(option.2)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 62)
                    .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? AppTheme.primary : AppTheme.secondarySurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(isSelected ? AppTheme.primary : AppTheme.divider, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ThemeSwatch: View {
    let config: ThemeConfig
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [config.primary, config.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 52)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isSelected ? AppTheme.primary : .clear, lineWidth: 3)
                    )
                    .shadow(color: isSelected ? config.primary.opacity(0.32) : .clear, radius: 8, y: 3)

                Text(config.name)
                    .font(.system(size: 9, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.primary : AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(minHeight: 22)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Service Management

private struct ServiceManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Service.sortOrder) private var services: [Service]
    @State private var isShowingForm = false

    var body: some View {
        List {
            ForEach(services) { service in
                NavigationLink {
                    ServiceFormView(service: service)
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: service.colorHex))
                            .frame(width: 12, height: 12)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(service.name)
                            Text("\(service.durationMinutes) dk · \(service.price.formatted(.currency(code: "TRY").precision(.fractionLength(0))))")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        if !service.isActive {
                            Spacer()
                            Text("Pasif")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .listRowBackground(AppTheme.surface)
            }
            .onMove(perform: moveServices)
            .onDelete(perform: deleteServices)
        }
        .navigationTitle("Hizmetler")
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isShowingForm = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $isShowingForm) {
            ServiceFormView()
        }
    }

    private func moveServices(from source: IndexSet, to destination: Int) {
        var reordered = services
        reordered.move(fromOffsets: source, toOffset: destination)
        for (idx, service) in reordered.enumerated() {
            service.sortOrder = idx
        }
        try? modelContext.save()
    }

    private func deleteServices(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(services[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Backup Document

private struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Business Form

private struct BusinessFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let business: Business
    @State private var name: String
    @State private var category: String
    @State private var phone: String
    @State private var address: String
    @State private var openingDate: Date
    @State private var closingDate: Date

    init(business: Business) {
        self.business = business
        _name = State(initialValue: business.name)
        _category = State(initialValue: business.category)
        _phone = State(initialValue: business.phone)
        _address = State(initialValue: business.address)
        _openingDate = State(initialValue: Self.date(from: business.openingTime))
        _closingDate = State(initialValue: Self.date(from: business.closingTime))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("İşletme") {
                    TextField("Ad", text: $name)
                    TextField("Kategori", text: $category)
                    TextField("Telefon", text: $phone)
                    TextField("Adres", text: $address, axis: .vertical)
                }
                Section("Çalışma Saatleri") {
                    DatePicker("Açılış", selection: $openingDate, displayedComponents: .hourAndMinute)
                    DatePicker("Kapanış", selection: $closingDate, displayedComponents: .hourAndMinute)
                    Text("Açılış ve kapanış aynı saat seçilirse 24 saat açık kabul edilir.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("İşletme")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        business.name = name
                        business.category = category
                        business.phone = phone
                        business.address = address
                        business.openingTime = Self.timeString(from: openingDate)
                        business.closingTime = Self.timeString(from: closingDate)
                        business.updatedAt = .now
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private static func date(from timeString: String) -> Date {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return .now }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour = parts[0]
        comps.minute = parts[1]
        return Calendar.current.date(from: comps) ?? .now
    }

    private static func timeString(from date: Date) -> String {
        let cal = Calendar.current
        return String(format: "%02d:%02d", cal.component(.hour, from: date), cal.component(.minute, from: date))
    }
}

// MARK: - Service Form

struct ServiceFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Service.sortOrder) private var services: [Service]
    private let service: Service?

    @State private var name: String
    @State private var durationMinutes: Int
    @State private var price: Double
    @State private var colorHex: String
    @State private var serviceDescription: String
    @State private var isActive: Bool

    private let colors = ["#5856D6", "#007AFF", "#30D158", "#FF2D55", "#FF9F0A", "#8E8E93", "#C9A84C", "#2D6A4F"]

    init(service: Service? = nil) {
        self.service = service
        _name = State(initialValue: service?.name ?? "")
        _durationMinutes = State(initialValue: service?.durationMinutes ?? 30)
        _price = State(initialValue: service?.price ?? 0)
        _colorHex = State(initialValue: service?.colorHex ?? "#5856D6")
        _serviceDescription = State(initialValue: service?.serviceDescription ?? "")
        _isActive = State(initialValue: service?.isActive ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Hizmet") {
                    TextField("Ad", text: $name)
                    Stepper("\(durationMinutes) dk", value: $durationMinutes, in: 5...360, step: 5)
                    HStack {
                        TextField("Fiyat", value: $price, format: .number)
                            .keyboardType(.decimalPad)
                        Text("TL")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Toggle("Aktif", isOn: $isActive)
                }

                Section("Renk") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                }

                Section("Açıklama") {
                    TextField("Açıklama", text: $serviceDescription, axis: .vertical)
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(service == nil ? "Hizmet Ekle" : "Hizmeti Düzenle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let service {
            service.name = trimmed
            service.durationMinutes = durationMinutes
            service.price = price
            service.colorHex = colorHex
            service.serviceDescription = serviceDescription
            service.isActive = isActive
        } else {
            modelContext.insert(Service(name: trimmed, durationMinutes: durationMinutes, colorHex: colorHex, sortOrder: services.count, price: price, serviceDescription: serviceDescription, isActive: isActive))
        }
        try? modelContext.save()
        dismiss()
    }
}
