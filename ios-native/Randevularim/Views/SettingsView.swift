import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Business.name) private var businesses: [Business]
    @Query(sort: \Service.sortOrder) private var services: [Service]
    @State private var isShowingBusinessForm = false
    @State private var isShowingServiceForm = false

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
                    Button("İşletmeyi Düzenle") {
                        isShowingBusinessForm = true
                    }
                }

                Section("Hizmetler") {
                    ForEach(services) { service in
                        NavigationLink {
                            ServiceFormView(service: service)
                        } label: {
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
                    .onDelete(perform: deleteServices)

                    Button("Hizmet Ekle") {
                        isShowingServiceForm = true
                    }
                }

                Section("Native iOS") {
                    Label("Yerel bildirimler aktif", systemImage: "bell.badge.fill")
                    Label("Live Activities hazırlığı", systemImage: "waveform.path.ecg")
                    Label("WidgetKit hazırlığı", systemImage: "rectangle.grid.2x2")
                    Label("Siri/App Intents hazırlığı", systemImage: "sparkles")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .sheet(isPresented: $isShowingBusinessForm) {
                BusinessFormView(business: business)
            }
            .sheet(isPresented: $isShowingServiceForm) {
                ServiceFormView()
            }
        }
    }

    private func deleteServices(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(services[index])
        }
        try? modelContext.save()
    }
}

private struct BusinessFormView: View {
    @Environment(\.dismiss) private var dismiss
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
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct ServiceFormView: View {
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
                                .onTapGesture {
                                    colorHex = hex
                                }
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
