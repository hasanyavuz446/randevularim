import SwiftUI
import SwiftData

struct AppointmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @State private var isShowingForm = false
    @State private var searchText = ""
    @State private var filter: AppointmentListFilter = .upcoming

    private var filteredAppointments: [Appointment] {
        appointments.filter { appointment in
            let matchesSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                appointment.customerName.localizedCaseInsensitiveContains(searchText) ||
                appointment.serviceName.localizedCaseInsensitiveContains(searchText) ||
                appointment.customerPhone.localizedCaseInsensitiveContains(searchText)
            return matchesSearch && filter.matches(appointment)
        }
    }

    var body: some View {
        RandevularimScreen(title: "Randevular") {
            List {
                Section {
                    Picker("Filtre", selection: $filter) {
                        ForEach(AppointmentListFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(AppTheme.background)
                }

                if filteredAppointments.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "Randevu bulunmuyor" : "Sonuç bulunamadı",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text(searchText.isEmpty ? "Bu filtrede gösterilecek randevu yok." : "Farklı bir arama veya filtre deneyin.")
                    )
                    .listRowBackground(AppTheme.background)
                } else {
                    ForEach(filteredAppointments) { appointment in
                        NavigationLink {
                            AppointmentDetailView(appointment: appointment)
                        } label: {
                            AppointmentListRow(appointment: appointment)
                        }
                        .listRowBackground(AppTheme.surface)
                    }
                    .onDelete(perform: deleteAppointments)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Müşteri, hizmet veya telefon ara")
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingForm) {
                AppointmentFormView()
            }
        }
    }

    private func deleteAppointments(at offsets: IndexSet) {
        for index in offsets {
            let appointment = filteredAppointments[index]
            NotificationScheduler.cancel(for: appointment)
            modelContext.delete(appointment)
        }
        try? modelContext.save()
    }
}

private enum AppointmentListFilter: String, CaseIterable, Identifiable {
    case upcoming
    case today
    case completed
    case cancelled
    case all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .upcoming: "Yaklaşan"
        case .today: "Bugün"
        case .completed: "Biten"
        case .cancelled: "İptal"
        case .all: "Tümü"
        }
    }

    func matches(_ appointment: Appointment) -> Bool {
        switch self {
        case .upcoming:
            appointment.dateTime >= .now && appointment.status != .cancelled && appointment.status != .completed && appointment.status != .noShow
        case .today:
            Calendar.current.isDateInToday(appointment.dateTime)
        case .completed:
            appointment.status == .completed
        case .cancelled:
            appointment.status == .cancelled || appointment.status == .noShow
        case .all:
            true
        }
    }
}

struct AppointmentListRow: View {
    let appointment: Appointment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(appointment.customerName)
                    .font(.headline)
                Spacer()
                Text(appointment.status.label)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.secondarySurface, in: Capsule())
            }

            Text(appointment.serviceName)
                .foregroundStyle(AppTheme.textSecondary)

            Text(appointment.dateTime.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(AppTheme.accent)
        }
    }
}

struct AppointmentDetailView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Bindable var appointment: Appointment
    @State private var isShowingEdit = false
    @State private var confirmation: AppointmentConfirmation?

    var body: some View {
        List {
            Section("Randevu") {
                LabeledContent("Müşteri", value: appointment.customerName)
                LabeledContent("Hizmet", value: appointment.serviceName)
                LabeledContent("Tarih", value: appointment.dateTime.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Süre", value: "\(appointment.durationMinutes) dk")
                LabeledContent("Ücret", value: appointment.totalPrice.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
            }

            Section("Durum") {
                Picker("Durum", selection: $appointment.status) {
                    ForEach(AppointmentStatus.allCases) { status in
                        Text(status.label).tag(status)
                    }
                }
                .onChange(of: appointment.status) { _, _ in
                    persistAppointmentChange()
                }
            }

            Section("Bildirim") {
                Toggle("Başlangıç Bildirimi", isOn: $appointment.startNotificationEnabled)
                    .onChange(of: appointment.startNotificationEnabled) { _, _ in persistAppointmentChange() }
                Toggle("Hatırlatma", isOn: $appointment.notificationsEnabled)
                    .onChange(of: appointment.notificationsEnabled) { _, _ in persistAppointmentChange() }
                LabeledContent("Hatırlatma Süresi", value: "\(appointment.reminderMinutes) dk önce")
            }

            Section("Hızlı İşlemler") {
                if appointment.status != .confirmed {
                    Button("Randevuyu Teyit Et") {
                        updateStatus(.confirmed)
                    }
                }
                if appointment.status != .completed {
                    Button("Tamamlandı Olarak İşaretle") {
                        confirmation = .complete
                    }
                }
                if appointment.status != .noShow {
                    Button("Müşteri Gelmedi") {
                        confirmation = .noShow
                    }
                    .foregroundStyle(AppTheme.warning)
                }
                if appointment.status != .cancelled {
                    Button("Randevuyu İptal Et", role: .destructive) {
                        confirmation = .cancel
                    }
                }
            }

            Section("İletişim") {
                Button("Ara") {
                    openURL(URL(string: "tel://\(appointment.customerPhone.filter(\.isNumber))")!)
                }
                Button("WhatsApp Yeni Randevu Mesajı") {
                    openWhatsApp(message: "\(appointment.customerName), \(appointment.dateTime.formatted(date: .abbreviated, time: .shortened)) tarihli \(appointment.serviceName) randevunuz oluşturuldu.")
                }
                Button("WhatsApp Hatırlatma") {
                    openWhatsApp(message: "\(appointment.customerName), \(appointment.dateTime.formatted(date: .abbreviated, time: .shortened)) tarihli \(appointment.serviceName) randevunuzu hatırlatırız.")
                }
            }

            if !appointment.notes.isEmpty {
                Section("Not") {
                    Text(appointment.notes)
                }
            }
        }
        .navigationTitle("Randevu")
        .toolbar {
            Button("Düzenle") {
                isShowingEdit = true
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            AppointmentFormView(appointment: appointment)
        }
        .alert(item: $confirmation) { confirmation in
            Alert(
                title: Text(confirmation.title),
                message: Text(confirmation.message),
                primaryButton: .default(Text("Devam")) {
                    updateStatus(confirmation.status)
                },
                secondaryButton: .cancel(Text("Vazgeç"))
            )
        }
    }

    private func openWhatsApp(message: String) {
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        openURL(URL(string: "whatsapp://send?phone=90\(appointment.customerPhone.filter(\.isNumber))&text=\(encoded)")!)
    }

    private func updateStatus(_ status: AppointmentStatus) {
        appointment.status = status
        persistAppointmentChange()
    }

    private func persistAppointmentChange() {
        try? modelContext.save()
        NotificationScheduler.schedule(for: appointment)
    }
}

private enum AppointmentConfirmation: String, Identifiable {
    case complete
    case noShow
    case cancel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .complete: "Randevu Tamamlandı"
        case .noShow: "Müşteri Gelmedi"
        case .cancel: "Randevuyu İptal Et"
        }
    }

    var message: String {
        switch self {
        case .complete: "Randevu tamamlandı olarak işaretlenecek."
        case .noShow: "Randevu gelmedi olarak kaydedilecek."
        case .cancel: "Bu randevu iptal edildi olarak işaretlenecek."
        }
    }

    var status: AppointmentStatus {
        switch self {
        case .complete: .completed
        case .noShow: .noShow
        case .cancel: .cancelled
        }
    }
}

struct AppointmentFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Customer.name) private var customers: [Customer]
    @Query(sort: \Service.sortOrder) private var services: [Service]
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @Query private var businesses: [Business]

    private let appointment: Appointment?
    @State private var customerId: String
    @State private var selectedServiceIds: Set<String>
    @State private var dateTime: Date
    @State private var durationMinutes: Int
    @State private var totalPrice: Double
    @State private var notes: String
    @State private var status: AppointmentStatus
    @State private var notificationsEnabled: Bool
    @State private var reminderMinutes: Int
    @State private var startNotificationEnabled: Bool

    init(appointment: Appointment? = nil, preselectedCustomerId: String = "") {
        self.appointment = appointment
        _customerId = State(initialValue: appointment?.customerId ?? preselectedCustomerId)
        _selectedServiceIds = State(initialValue: Set(appointment?.serviceIds ?? []))
        _dateTime = State(initialValue: appointment?.dateTime ?? .now)
        _durationMinutes = State(initialValue: appointment?.durationMinutes ?? 30)
        _totalPrice = State(initialValue: appointment?.totalPrice ?? 0)
        _notes = State(initialValue: appointment?.notes ?? "")
        _status = State(initialValue: appointment?.status ?? .scheduled)
        _notificationsEnabled = State(initialValue: appointment?.notificationsEnabled ?? true)
        _reminderMinutes = State(initialValue: appointment?.reminderMinutes ?? 30)
        _startNotificationEnabled = State(initialValue: appointment?.startNotificationEnabled ?? true)
    }

    private var selectedCustomer: Customer? {
        customers.first { $0.id == customerId } ?? customers.first
    }

    private var activeServices: [Service] {
        services.filter(\.isActive)
    }

    private var selectedServices: [Service] {
        let selected = activeServices.filter { selectedServiceIds.contains($0.id) }
        return selected.isEmpty ? Array(activeServices.prefix(1)) : selected
    }

    private var hasConflict: Bool {
        appointments.contains { existing in
            existing.id != appointment?.id && existing.status != .cancelled && existing.overlaps(with: dateTime, durationMinutes: durationMinutes)
        }
    }

    private var isOutsideWorkingHours: Bool {
        guard let business = businesses.first,
              let opening = timeComponents(from: business.openingTime),
              let closing = timeComponents(from: business.closingTime) else {
            return false
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: dateTime)
        let startMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let openingMinutes = opening.hour * 60 + opening.minute
        let closingMinutes = closing.hour * 60 + closing.minute
        return startMinutes < openingMinutes || startMinutes >= closingMinutes
    }

    var body: some View {
        NavigationStack {
            Form {
                if customers.isEmpty || services.isEmpty {
                    Section {
                        Text("Randevu oluşturmak için önce en az bir müşteri ve hizmet olmalı.")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                } else {
                    Section("Müşteri ve Hizmet") {
                        Picker("Müşteri", selection: $customerId) {
                            ForEach(customers) { customer in
                                Text(customer.name).tag(customer.id)
                            }
                        }

                        ForEach(activeServices) { service in
                            Button {
                                toggleService(service)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(service.name)
                                            .foregroundStyle(.primary)
                                        Text("\(service.durationMinutes) dk · \(service.price.formatted(.currency(code: "TRY").precision(.fractionLength(0))))")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: selectedServiceIds.contains(service.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedServiceIds.contains(service.id) ? AppTheme.primary : AppTheme.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Section("Zaman") {
                        DatePicker("Tarih ve Saat", selection: $dateTime)
                        Stepper("\(durationMinutes) dk", value: $durationMinutes, in: 5...480, step: 5)
                        if isOutsideWorkingHours {
                            Label("Randevu çalışma saatleri dışında.", systemImage: "clock.badge.exclamationmark")
                                .foregroundStyle(AppTheme.warning)
                        }
                        if hasConflict {
                            Label("Bu saat aralığında başka bir randevu var.", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppTheme.warning)
                        }
                    }

                    Section("Ücret ve Durum") {
                        TextField("Ücret", value: $totalPrice, format: .number)
                            .keyboardType(.decimalPad)
                        Picker("Durum", selection: $status) {
                            ForEach(AppointmentStatus.allCases) { status in
                                Text(status.label).tag(status)
                            }
                        }
                    }

                    Section("Bildirim") {
                        Toggle("Başlangıç Bildirimi", isOn: $startNotificationEnabled)
                        Toggle("Hatırlatma", isOn: $notificationsEnabled)
                        Stepper("\(reminderMinutes) dk önce", value: $reminderMinutes, in: 0...1440, step: 5)
                    }

                    Section("Not") {
                        TextField("Not", text: $notes, axis: .vertical)
                    }
                }
            }
            .navigationTitle(appointment == nil ? "Randevu Ekle" : "Randevuyu Düzenle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet", action: save)
                        .disabled(customers.isEmpty || services.isEmpty)
                }
            }
            .onAppear {
                if customerId.isEmpty {
                    customerId = customers.first?.id ?? ""
                }
                if selectedServiceIds.isEmpty, let firstService = activeServices.first {
                    selectedServiceIds = [firstService.id]
                    applySelectedService()
                }
            }
        }
    }

    private func applySelectedService() {
        let selected = selectedServices
        guard !selected.isEmpty else { return }
        durationMinutes = selected.reduce(0) { $0 + $1.durationMinutes }
        totalPrice = selected.reduce(0) { $0 + $1.price }
    }

    private func toggleService(_ service: Service) {
        if selectedServiceIds.contains(service.id), selectedServiceIds.count > 1 {
            selectedServiceIds.remove(service.id)
        } else {
            selectedServiceIds.insert(service.id)
        }
        applySelectedService()
    }

    private func save() {
        let selected = selectedServices
        guard let customer = selectedCustomer, !selected.isEmpty else { return }
        let serviceName = selected.map(\.name).joined(separator: " + ")
        let serviceColor = selected.first?.colorHex ?? "#5856D6"
        let serviceIds = selected.map(\.id)
        if let appointment {
            appointment.customerId = customer.id
            appointment.customerName = customer.name
            appointment.customerPhone = customer.phone
            appointment.dateTime = dateTime
            appointment.durationMinutes = durationMinutes
            appointment.serviceIds = serviceIds
            appointment.serviceName = serviceName
            appointment.serviceColor = serviceColor
            appointment.notes = notes
            appointment.status = status
            appointment.totalPrice = totalPrice
            appointment.notificationsEnabled = notificationsEnabled
            appointment.reminderMinutes = reminderMinutes
            appointment.startNotificationEnabled = startNotificationEnabled
        } else {
            let newAppointment = Appointment(
                customerId: customer.id,
                customerName: customer.name,
                customerPhone: customer.phone,
                dateTime: dateTime,
                durationMinutes: durationMinutes,
                serviceIds: serviceIds,
                serviceName: serviceName,
                serviceColor: serviceColor,
                notes: notes,
                status: status,
                totalPrice: totalPrice,
                notificationsEnabled: notificationsEnabled,
                reminderMinutes: reminderMinutes,
                startNotificationEnabled: startNotificationEnabled
            )
            modelContext.insert(newAppointment)
            NotificationScheduler.schedule(for: newAppointment)
            try? modelContext.save()
            dismiss()
            return
        }
        try? modelContext.save()
        if let appointment {
            NotificationScheduler.schedule(for: appointment)
        }
        dismiss()
    }

    private func timeComponents(from value: String) -> (hour: Int, minute: Int)? {
        let parts = value.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return (parts[0], parts[1])
    }
}
