import SwiftUI
import SwiftData

struct CustomerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Customer.name) private var customers: [Customer]
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @State private var isShowingForm = false
    @State private var appointmentCustomerId = ""
    @State private var isShowingAppointmentForm = false
    @State private var searchText = ""
    @State private var pendingDeletion: Customer?

    private var filteredCustomers: [Customer] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return customers }
        return customers.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
                $0.phone.localizedCaseInsensitiveContains(query) ||
                $0.serviceNotes.localizedCaseInsensitiveContains(query) ||
                $0.generalNotes.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        RandevularimScreen(title: "Müşteriler") {
            List {
                if filteredCustomers.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "Müşteri yok" : "Sonuç bulunamadı",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text(searchText.isEmpty ? "Yeni müşteri ekleyerek başlayın." : "Farklı bir arama deneyin.")
                    )
                    .listRowBackground(AppTheme.background)
                }

                ForEach(filteredCustomers) { customer in
                    NavigationLink {
                        CustomerDetailView(customer: customer)
                    } label: {
                        CustomerRow(customer: customer)
                    }
                    .listRowBackground(AppTheme.surface)
                    .swipeActions(edge: .leading) {
                        Button {
                            appointmentCustomerId = customer.id
                            isShowingAppointmentForm = true
                        } label: {
                            Label("Randevu", systemImage: "calendar.badge.plus")
                        }
                        .tint(AppTheme.primary)
                    }
                }
                .onDelete(perform: deleteCustomers)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Müşteri ara")
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
                CustomerFormView()
            }
            .sheet(isPresented: $isShowingAppointmentForm) {
                AppointmentFormView(preselectedCustomerId: appointmentCustomerId)
            }
            .alert(item: $pendingDeletion) { customer in
                let futureCount = futureAppointments(for: customer).count
                return Alert(
                    title: Text(futureCount > 0 ? "Gelecek Randevular Var" : "Müşteriyi Sil"),
                    message: Text(futureCount > 0 ? "\(customer.name) için \(futureCount) gelecek randevu var. Müşteriyi silerseniz bu randevular da silinir." : "\(customer.name) silinsin mi?"),
                    primaryButton: .destructive(Text("Sil")) {
                        deleteCustomer(customer)
                    },
                    secondaryButton: .cancel(Text("Vazgeç"))
                )
            }
        }
    }

    private func deleteCustomers(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        pendingDeletion = filteredCustomers[index]
    }

    private func futureAppointments(for customer: Customer) -> [Appointment] {
        appointments.filter { $0.customerId == customer.id && $0.dateTime >= .now && $0.status != .cancelled }
    }

    private func deleteCustomer(_ customer: Customer) {
        for appointment in appointments where appointment.customerId == customer.id {
            NotificationScheduler.cancel(for: appointment)
            modelContext.delete(appointment)
        }
        modelContext.delete(customer)
        try? modelContext.save()
    }
}

private struct CustomerRow: View {
    let customer: Customer

    var body: some View {
        HStack(spacing: 12) {
            Text(customer.initials)
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text(customer.name)
                    .font(.headline)
                Text(customer.phone)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

private struct CustomerDetailView: View {
    @Environment(\.openURL) private var openURL
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @Bindable var customer: Customer
    @State private var isShowingEdit = false
    @State private var isShowingAppointmentForm = false

    private var customerAppointments: [Appointment] {
        appointments
            .filter { $0.customerId == customer.id }
            .sorted { $0.dateTime > $1.dateTime }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    Text(customer.initials)
                        .font(.title2.bold())
                        .frame(width: 58, height: 58)
                        .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(customer.name)
                            .font(.title3.bold())
                        Text(customer.phone)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }

            Section("İletişim") {
                Button("Ara") {
                    openURL(URL(string: "tel://\(customer.phone.filter(\.isNumber))")!)
                }
                Button("WhatsApp") {
                    openURL(URL(string: "whatsapp://send?phone=90\(customer.phone.filter(\.isNumber))")!)
                }
                Button("Bu Müşteriye Randevu Ekle") {
                    isShowingAppointmentForm = true
                }
            }

            Section("Notlar") {
                if customer.serviceNotes.isEmpty && customer.generalNotes.isEmpty {
                    Text("Not yok")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                if !customer.serviceNotes.isEmpty {
                    LabeledContent("Hizmet", value: customer.serviceNotes)
                }
                if !customer.generalNotes.isEmpty {
                    LabeledContent("Genel", value: customer.generalNotes)
                }
            }

            Section("Randevu Geçmişi (\(customerAppointments.count))") {
                if customerAppointments.isEmpty {
                    Text("Bu müşteri için randevu yok")
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    ForEach(customerAppointments) { appointment in
                        NavigationLink {
                            AppointmentDetailView(appointment: appointment)
                        } label: {
                            AppointmentListRow(appointment: appointment)
                        }
                    }
                }
            }
        }
        .navigationTitle("Müşteri")
        .toolbar {
            Button("Düzenle") {
                isShowingEdit = true
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            CustomerFormView(customer: customer)
        }
        .sheet(isPresented: $isShowingAppointmentForm) {
            AppointmentFormView(preselectedCustomerId: customer.id)
        }
    }
}

private struct CustomerFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    private let customer: Customer?

    @State private var name: String
    @State private var phone: String
    @State private var serviceNotes: String
    @State private var generalNotes: String

    init(customer: Customer? = nil) {
        self.customer = customer
        _name = State(initialValue: customer?.name ?? "")
        _phone = State(initialValue: customer?.phone ?? "")
        _serviceNotes = State(initialValue: customer?.serviceNotes ?? "")
        _generalNotes = State(initialValue: customer?.generalNotes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Müşteri") {
                    TextField("Ad Soyad", text: $name)
                    TextField("Telefon", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("Notlar") {
                    TextField("Hizmet notu", text: $serviceNotes, axis: .vertical)
                    TextField("Genel not", text: $generalNotes, axis: .vertical)
                }
            }
            .navigationTitle(customer == nil ? "Müşteri Ekle" : "Müşteriyi Düzenle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if let customer {
            customer.name = trimmedName
            customer.phone = trimmedPhone
            customer.serviceNotes = serviceNotes
            customer.generalNotes = generalNotes
        } else {
            modelContext.insert(Customer(name: trimmedName, phone: trimmedPhone, serviceNotes: serviceNotes, generalNotes: generalNotes))
        }
        try? modelContext.save()
        dismiss()
    }
}
