import SwiftUI
import SwiftData
import Contacts

struct ContactPickerSheet: View {
    var onComplete: ((Int) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \Customer.name) private var existingCustomers: [Customer]

    @State private var contacts: [CNContact] = []
    @State private var selectedIds: Set<String> = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var accessDenied = false

    private var existingPhoneDigits: Set<String> {
        Set(existingCustomers.map { $0.phone.filter(\.isNumber) })
    }

    private var filteredContacts: [CNContact] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return contacts }
        return contacts.filter {
            fullName($0).localizedCaseInsensitiveContains(q) ||
            ($0.phoneNumbers.first?.value.stringValue ?? "").contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Rehber yükleniyor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.background)
                } else if accessDenied {
                    permissionDeniedView
                } else if contacts.isEmpty {
                    ContentUnavailableView(
                        "Rehber boş",
                        systemImage: "person.crop.circle",
                        description: Text("Telefon numarası olan kişi bulunamadı.")
                    )
                    .background(AppTheme.background)
                } else {
                    contactList
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Rehberden Aktar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                // Aktar butonları alt bara taşındı — searchable aktifken üst toolbar kayboluyor
                if !contacts.isEmpty && !accessDenied {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button("Herkesi Aktar") { doImport(filteredContacts) }
                        Spacer()
                        Button(selectedIds.isEmpty ? "Seçilenleri Aktar" : "Aktar (\(selectedIds.count))") {
                            doImport(contacts.filter { selectedIds.contains($0.identifier) })
                        }
                        .fontWeight(.semibold)
                        .disabled(selectedIds.isEmpty)
                    }
                }
            }
        }
        .task { await loadContacts() }
        .presentationDetents([.large])
    }

    private var contactList: some View {
        List {
            ForEach(filteredContacts, id: \.identifier) { contact in
                let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
                let alreadyAdded = existingPhoneDigits.contains(phone.filter(\.isNumber))
                let isSelected = selectedIds.contains(contact.identifier)

                Button {
                    guard !alreadyAdded else { return }
                    if isSelected { selectedIds.remove(contact.identifier) }
                    else { selectedIds.insert(contact.identifier) }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: alreadyAdded ? "checkmark.circle.fill" : (isSelected ? "checkmark.circle.fill" : "circle"))
                            .font(.title3)
                            .foregroundStyle(alreadyAdded ? AppTheme.success : (isSelected ? AppTheme.primary : AppTheme.textSecondary))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(fullName(contact))
                                .font(.headline)
                                .foregroundStyle(alreadyAdded ? AppTheme.textSecondary : AppTheme.textPrimary)
                            if !phone.isEmpty {
                                Text(phone)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }

                        if alreadyAdded {
                            Spacer()
                            Text("Eklendi")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.success)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.success.opacity(0.12), in: Capsule())
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(AppTheme.surface)
                .disabled(alreadyAdded)
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "İsim veya telefon ara")
        .scrollDismissesKeyboard(.immediately)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(AppTheme.textSecondary)
            Text("Rehber erişimi yok")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("Ayarlar > Gizlilik > Kişiler bölümünden erişim iznini açın.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Ayarları Aç") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }

    private func loadContacts() async {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            guard granted else {
                accessDenied = true
                isLoading = false
                return
            }
            let keys: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor
            ]
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .userDefault
            var loaded: [CNContact] = []
            try store.enumerateContacts(with: request) { contact, _ in
                guard !contact.phoneNumbers.isEmpty else { return }
                loaded.append(contact)
            }
            contacts = loaded
        } catch {
            // erişim reddedildi veya fetch hatası
            accessDenied = true
        }
        isLoading = false
    }

    private func doImport(_ toImport: [CNContact]) {
        let existing = existingPhoneDigits
        var count = 0
        for contact in toImport {
            guard let phone = contact.phoneNumbers.first?.value.stringValue else { continue }
            let digits = phone.filter(\.isNumber)
            guard !digits.isEmpty, !existing.contains(digits) else { continue }
            let name = fullName(contact)
            modelContext.insert(Customer(name: name.isEmpty ? phone : name, phone: phone))
            count += 1
        }
        try? modelContext.save()
        onComplete?(count)
        dismiss()
    }

    private func fullName(_ contact: CNContact) -> String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }
}
