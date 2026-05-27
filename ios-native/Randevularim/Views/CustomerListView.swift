import SwiftUI
import SwiftData

struct CustomerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Customer.name) private var customers: [Customer]
    @State private var isShowingForm = false

    var body: some View {
        RandevularimScreen(title: "Müşteriler") {
            List {
                ForEach(customers) { customer in
                    NavigationLink {
                        CustomerDetailView(customer: customer)
                    } label: {
                        CustomerRow(customer: customer)
                    }
                    .listRowBackground(AppTheme.surface)
                }
                .onDelete(perform: deleteCustomers)
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
                CustomerFormView()
            }
        }
    }

    private func deleteCustomers(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(customers[index])
        }
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
    @Bindable var customer: Customer
    @State private var isShowingEdit = false

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
