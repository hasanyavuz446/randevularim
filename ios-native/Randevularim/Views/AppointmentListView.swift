import SwiftUI
import SwiftData

struct AppointmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @State private var isShowingForm = false
    @State private var searchText = ""
    @State private var filter: AppointmentListFilter = .upcoming
    @AppStorage("themeRevision") private var themeRevision = 0

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
        let _ = themeRevision
        RandevularimScreen(title: "Randevular") {
            List {
                Section {
                    ThemeSegmentedControl(selection: $filter)
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
    case upcoming = "Yaklaşan"
    case today = "Bugün"
    case completed = "Biten"
    case cancelled = "İptal"
    case all = "Tümü"

    var id: String { rawValue }

    var label: String {
        rawValue
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
                Text(appointment.status.label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(appointment.status.displayColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(appointment.status.displayColor.opacity(0.15), in: Capsule())
            }
            Text(appointment.serviceName)
                .foregroundStyle(AppTheme.textSecondary)
            Text(appointment.dateTime.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(AppTheme.accent)
        }
    }
}

// MARK: - Detail

struct AppointmentDetailView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Bindable var appointment: Appointment
    @Query private var businesses: [Business]
    @State private var isShowingEdit = false
    @State private var confirmation: AppointmentConfirmation?
    @State private var showWhatsAppSheet = false

    private var businessName: String { businesses.first?.name ?? "İşletmem" }

    var body: some View {
        List {
            Section("Randevu") {
                LabeledContent("Müşteri", value: appointment.customerName)
                LabeledContent("Hizmet", value: appointment.serviceName)
                LabeledContent("Tarih", value: appointment.dateTime.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Süre", value: "\(appointment.durationMinutes) dk")
                LabeledContent("Ücret", value: appointment.totalPrice.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                LabeledContent("Durum") {
                    Text(appointment.status.label)
                        .foregroundStyle(appointment.status.displayColor)
                }
            }

            Section("Bildirim") {
                Toggle("Başlangıç Bildirimi", isOn: $appointment.startNotificationEnabled)
                    .onChange(of: appointment.startNotificationEnabled) { _, _ in persistAppointmentChange() }
                Toggle("Hatırlatma", isOn: $appointment.notificationsEnabled)
                    .onChange(of: appointment.notificationsEnabled) { _, _ in persistAppointmentChange() }
                if appointment.notificationsEnabled {
                    LabeledContent("Hatırlatma Süresi", value: reminderLabel(appointment.reminderMinutes))
                }
            }

            Section("Durum") {
                if appointment.status != .confirmed {
                    Button("Randevuyu Teyit Et") { updateStatus(.confirmed) }
                }
                if appointment.status != .completed {
                    Button("Tamamlandı Olarak İşaretle") { confirmation = .complete }
                        .foregroundStyle(AppTheme.success)
                }
                if appointment.status != .noShow {
                    Button("Müşteri Gelmedi") { confirmation = .noShow }
                        .foregroundStyle(AppTheme.warning)
                }
                if appointment.status != .cancelled {
                    Button("Randevuyu İptal Et", role: .destructive) { confirmation = .cancel }
                }
            }

            Section("İletişim") {
                Button {
                    openURL(URL(string: "tel://\(appointment.customerPhone.filter(\.isNumber))")!)
                } label: {
                    Label("Ara", systemImage: "phone.fill")
                }

                Button {
                    showWhatsAppSheet = true
                } label: {
                    Label("WhatsApp", systemImage: "message.fill")
                }
            }

            if !appointment.notes.isEmpty {
                Section("Not") {
                    Text(appointment.notes)
                }
            }
        }
        .navigationTitle("Randevu Detayı")
        .toolbar {
            Button("Düzenle") { isShowingEdit = true }
        }
        .sheet(isPresented: $isShowingEdit) {
            AppointmentFormView(appointment: appointment)
        }
        .alert("WhatsApp Mesajı", isPresented: $showWhatsAppSheet) {
            Button("Yeni Randevu Mesajı") { sendWhatsApp(template: .newAppointment) }
            Button("Randevu Hatırlatması") { sendWhatsApp(template: .reminder) }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Müşteriye gönderilecek mesaj tipini seçin.")
        }
        .alert(item: $confirmation) { conf in
            Alert(
                title: Text(conf.title),
                message: Text(conf.message),
                primaryButton: .default(Text("Devam")) { updateStatus(conf.status) },
                secondaryButton: .cancel(Text("Vazgeç"))
            )
        }
    }

    private enum WhatsAppTemplate {
        case newAppointment, reminder
    }

    private func sendWhatsApp(template: WhatsAppTemplate) {
        let dateStr = appointment.dateTime.formatted(
            .dateTime.day().month(.wide).locale(Locale(identifier: "tr_TR"))
        )
        let timeStr = appointment.dateTime.formatted(date: .omitted, time: .shortened)

        let message: String
        switch template {
        case .newAppointment:
            message = "Merhaba \(appointment.customerName), \(businessName) randevunuz \(dateStr) tarihinde saat \(timeStr) için oluşturulmuştur. Görüşmek üzere!"
        case .reminder:
            let weekdayStr = appointment.dateTime.formatted(
                .dateTime.weekday(.wide).locale(Locale(identifier: "tr_TR"))
            )
            message = "Merhaba \(appointment.customerName), \(dateStr) \(weekdayStr) saat \(timeStr) randevunuz olduğunu hatırlatmak isteriz. Görüşmek üzere!"
        }

        let digits = appointment.customerPhone.filter(\.isNumber)
        let normalized = digits.hasPrefix("0") ? "9\(digits)" : (digits.hasPrefix("90") ? digits : "90\(digits)")
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://wa.me/\(normalized)?text=\(encoded)") {
            openURL(url)
        }
    }

    private func updateStatus(_ status: AppointmentStatus) {
        appointment.status = status
        persistAppointmentChange()
        if status == .completed || status == .cancelled || status == .noShow {
            #if canImport(ActivityKit)
            LiveActivityManager.end(for: appointment)
            #endif
        }
    }

    private func persistAppointmentChange() {
        try? modelContext.save()
        NotificationScheduler.schedule(for: appointment)
    }

    private func reminderLabel(_ minutes: Int) -> String {
        if minutes == 0 { return "Tam zamanında" }
        if minutes < 60 { return "\(minutes) dk önce" }
        if minutes == 1440 { return "1 gün önce" }
        let hours = minutes / 60
        let rem = minutes % 60
        return rem == 0 ? "\(hours) sa önce" : "\(hours) sa \(rem) dk önce"
    }
}

private enum AppointmentConfirmation: String, Identifiable {
    case complete, noShow, cancel

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

// MARK: - Form

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
    @State private var weeklyRepeatCount: Int
    @State private var isShowingCustomerPicker = false

    init(appointment: Appointment? = nil, preselectedCustomerId: String = "", initialDate: Date = .now) {
        self.appointment = appointment
        _customerId = State(initialValue: appointment?.customerId ?? preselectedCustomerId)
        _selectedServiceIds = State(initialValue: Set(appointment?.serviceIds ?? []))
        _dateTime = State(initialValue: appointment?.dateTime ?? initialDate)
        _durationMinutes = State(initialValue: appointment?.durationMinutes ?? 30)
        _totalPrice = State(initialValue: appointment?.totalPrice ?? 0)
        _notes = State(initialValue: appointment?.notes ?? "")
        _status = State(initialValue: appointment?.status ?? .scheduled)
        _notificationsEnabled = State(initialValue: appointment?.notificationsEnabled ?? true)
        _reminderMinutes = State(initialValue: appointment?.reminderMinutes ?? 30)
        _startNotificationEnabled = State(initialValue: appointment?.startNotificationEnabled ?? true)
        _weeklyRepeatCount = State(initialValue: 1)
    }

    private var selectedCustomer: Customer? {
        customers.first { $0.id == customerId }
    }

    private var activeServices: [Service] { services.filter(\.isActive) }

    private var selectedServices: [Service] {
        let selected = activeServices.filter { selectedServiceIds.contains($0.id) }
        return selected.isEmpty ? Array(activeServices.prefix(1)) : selected
    }

    private var hasConflict: Bool {
        appointments.contains { existing in
            existing.id != appointment?.id &&
            existing.status != .cancelled &&
            existing.overlaps(with: dateTime, durationMinutes: durationMinutes)
        }
    }

    private var isOutsideWorkingHours: Bool {
        guard let biz = businesses.first,
              let opening = timeComponents(from: biz.openingTime),
              let closing = timeComponents(from: biz.closingTime) else { return false }
        let openMins = opening.hour * 60 + opening.minute
        let closeMins = closing.hour * 60 + closing.minute
        if openMins == closeMins { return false }
        let cal = Calendar.current
        let start = cal.component(.hour, from: dateTime) * 60 + cal.component(.minute, from: dateTime)
        return start < openMins || start >= closeMins
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
                    Section("Müşteri") {
                        Button {
                            isShowingCustomerPicker = true
                        } label: {
                            HStack {
                                if let customer = selectedCustomer {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(customer.name)
                                            .foregroundStyle(.primary)
                                        if !customer.phone.isEmpty {
                                            Text(customer.phone)
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }
                                    }
                                } else {
                                    Text("Müşteri Seç")
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    Section("Hizmetler") {
                        ForEach(activeServices) { service in
                            Button {
                                toggleService(service)
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color(hex: service.colorHex))
                                        .frame(width: 10, height: 10)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(service.name).foregroundStyle(.primary)
                                        Text("\(service.durationMinutes) dk · \(service.price.formatted(.currency(code: "TRY").precision(.fractionLength(0))))")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: selectedServiceIds.contains(service.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(selectedServiceIds.contains(service.id) ? AppTheme.primary : AppTheme.textSecondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Section("Süre") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                durationButton(mins: 15, label: "15 dk")
                                durationButton(mins: 30, label: "30 dk")
                                durationButton(mins: 45, label: "45 dk")
                                durationButton(mins: 60, label: "1 sa")
                                durationButton(mins: 90, label: "1.5 sa")
                                durationButton(mins: 120, label: "2 sa")
                            }
                            .padding(.vertical, 4)
                        }
                        Stepper("\(durationMinutes) dk", value: $durationMinutes, in: 5...480, step: 5)
                    }

                    Section("Zaman") {
                        DatePicker("Tarih ve Saat", selection: $dateTime)
                        if isOutsideWorkingHours {
                            Label("Randevu çalışma saatleri dışında.", systemImage: "clock.badge.exclamationmark")
                                .foregroundStyle(AppTheme.warning)
                        }
                        if hasConflict {
                            Label("Bu saat aralığında başka bir randevu var.", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppTheme.warning)
                        }
                    }

                    if appointment == nil {
                        Section("Tekrar") {
                            Picker("Tekrar", selection: $weeklyRepeatCount) {
                                Text("Tek randevu").tag(1)
                                Text("4 hafta boyunca tekrarla").tag(4)
                                Text("8 hafta boyunca tekrarla").tag(8)
                                Text("12 hafta boyunca tekrarla").tag(12)
                            }
                            if weeklyRepeatCount > 1 {
                                Label("\(weeklyRepeatCount) randevu oluşturulacak", systemImage: "arrow.clockwise")
                                    .foregroundStyle(AppTheme.accent)
                                    .font(.caption)
                            }
                        }
                    }

                    Section("Ücret") {
                        HStack {
                            TextField("Ücret", value: $totalPrice, format: .number)
                                .keyboardType(.decimalPad)
                            Text("TL")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    Section("Durum") {
                        Picker("Durum", selection: $status) {
                            ForEach(AppointmentStatus.allCases) { status in
                                Text(status.label).tag(status)
                            }
                        }
                    }

                    Section("Bildirim") {
                        Toggle("Başlangıç Bildirimi", isOn: $startNotificationEnabled)
                        Toggle("Hatırlatma", isOn: $notificationsEnabled)
                        if notificationsEnabled {
                            Stepper("\(reminderMinutes) dk önce", value: $reminderMinutes, in: 0...1440, step: 5)
                        }
                    }

                    Section("Randevu Notu") {
                        TextField("Not", text: $notes, axis: .vertical)
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(appointment == nil ? "Randevu Ekle" : "Randevuyu Düzenle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet", action: save)
                        .disabled(customers.isEmpty || services.isEmpty || selectedCustomer == nil)
                }

            }
            .onAppear {
                if selectedServiceIds.isEmpty, let first = activeServices.first {
                    selectedServiceIds = [first.id]
                    applySelectedServices()
                }
            }
            .sheet(isPresented: $isShowingCustomerPicker) {
                CustomerPickerSheet(customers: customers, selectedId: $customerId)
            }
        }
    }

    private func durationButton(mins: Int, label: String) -> some View {
        Button(label) { durationMinutes = mins }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(durationMinutes == mins ? AppTheme.primary : AppTheme.secondarySurface, in: Capsule())
            .foregroundStyle(durationMinutes == mins ? .white : AppTheme.textPrimary)
            .buttonStyle(.plain)
    }

    private func applySelectedServices() {
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
        applySelectedServices()
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
            try? modelContext.save()
            NotificationScheduler.schedule(for: appointment)
        } else {
            for week in 0..<weeklyRepeatCount {
                guard let apptDate = Calendar.current.date(byAdding: .weekOfYear, value: week, to: dateTime) else { continue }
                let newAppointment = Appointment(
                    customerId: customer.id,
                    customerName: customer.name,
                    customerPhone: customer.phone,
                    dateTime: apptDate,
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
            }
            try? modelContext.save()
        }
        dismiss()
    }

    private func timeComponents(from value: String) -> (hour: Int, minute: Int)? {
        let parts = value.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return (parts[0], parts[1])
    }
}

// MARK: - Customer Picker Sheet

private struct CustomerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let customers: [Customer]
    @Binding var selectedId: String
    @State private var searchText = ""

    private var filtered: [Customer] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return customers }
        return customers.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.phone.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    ContentUnavailableView("Sonuç bulunamadı", systemImage: "person.crop.circle.badge.questionmark")
                        .listRowBackground(AppTheme.background)
                } else {
                    ForEach(filtered) { customer in
                        Button {
                            selectedId = customer.id
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(customer.name).font(.headline)
                                    if !customer.phone.isEmpty {
                                        Text(customer.phone)
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                }
                                Spacer()
                                if selectedId == customer.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.primary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(AppTheme.surface)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "İsim veya telefon ara")
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("Müşteri Seç")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
            }
        }
    }
}
