import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Contacts

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \Business.name) private var businesses: [Business]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("globalNotificationsEnabled") private var globalNotificationsEnabled = true
    @AppStorage("defaultReminderMinutes") private var defaultReminderMinutes = 30
    @AppStorage("selectedThemeId") private var selectedThemeId = "night_blue"
    @AppStorage("themeVersion") private var themeVersion = 0
    @AppStorage("colorSchemePref") private var colorSchemePref = "dark"
    @State private var isShowingBusinessForm = false
    @State private var exportDocument: BackupDocument?
    @State private var isShowingExporter = false
    @State private var isShowingImporter = false
    @State private var statusMessage: String?
    @State private var isShowingContactsAlert = false
    @State private var isImportingContacts = false
    @State private var isShowingResetConfirm = false

    private var business: Business { businesses.first ?? Business.defaultBusiness() }

    var body: some View {
        RandevularimScreen(title: "Ayarlar") {
            List {
                Section("Görünüm") {
                    Picker("Renk Modu", selection: Binding(
                        get: { colorSchemePref },
                        set: { newValue in
                            colorSchemePref = newValue
                            AppTheme.apply(id: selectedThemeId, colorSchemePref: newValue)
                            themeVersion += 1
                        }
                    )) {
                        Text("Açık").tag("light")
                        Text("Koyu").tag("dark")
                        Text("Otomatik").tag("auto")
                    }
                    .pickerStyle(.segmented)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(ThemeConfig.all, id: \.id) { config in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(config.primary)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if selectedThemeId == config.id {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .overlay {
                                        Circle().strokeBorder(selectedThemeId == config.id ? .white : .clear, lineWidth: 2)
                                    }
                                Text(config.name)
                                    .font(.system(size: 9))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            .onTapGesture {
                                selectedThemeId = config.id
                                AppTheme.apply(id: config.id, colorSchemePref: colorSchemePref)
                                themeVersion += 1
                            }
                        }
                    }
                    .padding(.vertical, 6)
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
                    Button {
                        handleContactImport()
                    } label: {
                        HStack {
                            Text("Rehberden Müşteri Aktar")
                            if isImportingContacts {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isImportingContacts)
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

                Section {
                    Button("Tüm Verileri Sıfırla", role: .destructive) {
                        isShowingResetConfirm = true
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
            .confirmationDialog("Tüm Verileri Sıfırla", isPresented: $isShowingResetConfirm, titleVisibility: .visible) {
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
            .alert("Rehber Erişimi Gerekli", isPresented: $isShowingContactsAlert) {
                Button("Ayarları Aç") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Rehbere erişim izni verilmemiş. Ayarlar > Gizlilik > Kişiler bölümünden izin verin.")
            }
        }
    }

    private func handleContactImport() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .denied || status == .restricted {
            isShowingContactsAlert = true
            return
        }
        isImportingContacts = true
        Task {
            defer { isImportingContacts = false }
            do {
                let count = try await ContactImportService.importContacts(into: modelContext)
                statusMessage = "\(count) müşteri aktarıldı."
            } catch {
                statusMessage = "Rehber aktarılamadı: \(error.localizedDescription)"
            }
        }
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
    @State private var openingTime: String
    @State private var closingTime: String

    init(business: Business) {
        self.business = business
        _name = State(initialValue: business.name)
        _category = State(initialValue: business.category)
        _phone = State(initialValue: business.phone)
        _address = State(initialValue: business.address)
        _openingTime = State(initialValue: business.openingTime)
        _closingTime = State(initialValue: business.closingTime)
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
                    TextField("Açılış", text: $openingTime)
                    TextField("Kapanış", text: $closingTime)
                }
            }
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
                        business.openingTime = openingTime
                        business.closingTime = closingTime
                        business.updatedAt = .now
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
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
                    TextField("Fiyat", value: $price, format: .number)
                        .keyboardType(.decimalPad)
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
