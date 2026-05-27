import SwiftUI
import SwiftData

struct AppointmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @State private var isShowingForm = false

    var body: some View {
        RandevularimScreen(title: "Randevular") {
            List {
                ForEach(appointments) { appointment in
                    NavigationLink {
                        AppointmentDetailView(appointment: appointment)
                    } label: {
                        AppointmentListRow(appointment: appointment)
                    }
                    .listRowBackground(AppTheme.surface)
                }
                .onDelete(perform: deleteAppointments)
            }
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
            let appointment = appointments[index]
            NotificationScheduler.cancel(for: appointment)
            modelContext.delete(appointment)
        }
        try? modelContext.save()
    }
}

private struct AppointmentListRow: View {
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

private struct AppointmentDetailView: View {
    @Environment(\.openURL) private var openURL
    @Bindable var appointment: Appointment
    @State private var isShowingEdit = false

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
            }

            Section("Bildirim") {
                Toggle("Başlangıç Bildirimi", isOn: $appointment.startNotificationEnabled)
                Toggle("Hatırlatma", isOn: $appointment.notificationsEnabled)
                LabeledContent("Hatırlatma Süresi", value: "\(appointment.reminderMinutes) dk önce")
            }

            Section("İletişim") {
                Button("Ara") {
                    openURL(URL(string: "tel://\(appointment.customerPhone.filter(\.isNumber))")!)
                }
                Button("WhatsApp Hatırlatma") {
                    let message = "\(appointment.customerName), \(appointment.dateTime.formatted(date: .abbreviated, time: .shortened)) tarihli \(appointment.serviceName) randevunuzu hatırlatırız."
                    let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    openURL(URL(string: "whatsapp://send?phone=90\(appointment.customerPhone.filter(\.isNumber))&text=\(encoded)")!)
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
    }
}

private struct AppointmentFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Customer.name) private var customers: [Customer]
    @Query(sort: \Service.sortOrder) private var services: [Service]
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]

    private let appointment: Appointment?
    @State private var customerId: String
    @State private var serviceId: String
    @State private var dateTime: Date
    @State private var durationMinutes: Int
    @State private var totalPrice: Double
    @State private var notes: String
    @State private var status: AppointmentStatus
    @State private var notificationsEnabled: Bool
    @State private var reminderMinutes: Int
    @State private var startNotificationEnabled: Bool

    init(appointment: Appointment? = nil) {
        self.appointment = appointment
        _customerId = State(initialValue: appointment?.customerId ?? "")
        _serviceId = State(initialValue: appointment?.serviceIds.first ?? "")
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

    private var selectedService: Service? {
        services.first { $0.id == serviceId } ?? services.first
    }

    private var hasConflict: Bool {
        appointments.contains { existing in
            existing.id != appointment?.id && existing.status != .cancelled && existing.overlaps(with: dateTime, durationMinutes: durationMinutes)
        }
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

                        Picker("Hizmet", selection: $serviceId) {
                            ForEach(services.filter(\.isActive)) { service in
                                Text(service.name).tag(service.id)
                            }
                        }
                        .onChange(of: serviceId) { _, _ in
                            applySelectedService()
                        }
                    }

                    Section("Zaman") {
                        DatePicker("Tarih ve Saat", selection: $dateTime)
                        Stepper("\(durationMinutes) dk", value: $durationMinutes, in: 5...480, step: 5)
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
                if serviceId.isEmpty {
                    serviceId = services.first?.id ?? ""
                    applySelectedService()
                }
            }
        }
    }

    private func applySelectedService() {
        guard appointment == nil, let service = selectedService else { return }
        durationMinutes = service.durationMinutes
        totalPrice = service.price
    }

    private func save() {
        guard let customer = selectedCustomer, let service = selectedService else { return }
        if let appointment {
            appointment.customerId = customer.id
            appointment.customerName = customer.name
            appointment.customerPhone = customer.phone
            appointment.dateTime = dateTime
            appointment.durationMinutes = durationMinutes
            appointment.serviceIds = [service.id]
            appointment.serviceName = service.name
            appointment.serviceColor = service.colorHex
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
                serviceIds: [service.id],
                serviceName: service.name,
                serviceColor: service.colorHex,
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
}
