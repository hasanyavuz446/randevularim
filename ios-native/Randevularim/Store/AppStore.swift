import Foundation
import SwiftData
import UserNotifications
import Contacts
import AppIntents
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(ActivityKit)
import ActivityKit
#endif

enum SeedDataService {
    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let businessCount = (try? context.fetchCount(FetchDescriptor<Business>())) ?? 0
        if businessCount == 0 {
            let biz = Business(name: "İşletmem")
            context.insert(biz)
        }

        let serviceCount = (try? context.fetchCount(FetchDescriptor<Service>())) ?? 0
        if serviceCount == 0 {
            Service.defaults.forEach(context.insert)
        }

        #if targetEnvironment(simulator)
        seedScreenshotDataIfNeeded(in: context)
        #endif

        try? context.save()
    }

    @MainActor
    private static func seedScreenshotDataIfNeeded(in context: ModelContext) {
        let customerCount = (try? context.fetchCount(FetchDescriptor<Customer>())) ?? 0
        guard customerCount == 0 else { return }

        let c1 = Customer(name: "Samet Can", phone: "05301234567")
        let c2 = Customer(name: "Vural Toprak", phone: "05319876543")
        let c3 = Customer(name: "Arzu Vural", phone: "05354445566")
        [c1, c2, c3].forEach(context.insert)

        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        func dt(_ hour: Int, _ min: Int, _ dayOffset: Int = 0) -> Date {
            cal.date(bySettingHour: hour, minute: min, second: 0, of: cal.date(byAdding: .day, value: dayOffset, to: today)!)!
        }

        let a1 = Appointment(customerId: c1.id, customerName: c1.name, customerPhone: c1.phone,
                             dateTime: dt(18, 0), durationMinutes: 30, serviceIds: [],
                             serviceName: "Genel Randevu", serviceColor: "#5856D6",
                             notes: "", status: .completed, totalPrice: 2000)
        let a2 = Appointment(customerId: c2.id, customerName: c2.name, customerPhone: c2.phone,
                             dateTime: dt(20, 30), durationMinutes: 60, serviceIds: [],
                             serviceName: "Bakım / Uygulama", serviceColor: "#FF9F0A",
                             notes: "", totalPrice: 1500)
        let a3 = Appointment(customerId: c3.id, customerName: c3.name, customerPhone: c3.phone,
                             dateTime: dt(16, 35, 1), durationMinutes: 30, serviceIds: [],
                             serviceName: "Danışmanlık", serviceColor: "#007AFF",
                             notes: "", totalPrice: 800)
        [a1, a2, a3].forEach(context.insert)
    }

    @MainActor
    static func resetAllData(in context: ModelContext) throws {
        for item in try context.fetch(FetchDescriptor<Appointment>()) {
            NotificationScheduler.cancel(for: item)
            context.delete(item)
        }
        for item in try context.fetch(FetchDescriptor<Customer>()) { context.delete(item) }
        for item in try context.fetch(FetchDescriptor<Service>()) { context.delete(item) }
        for item in try context.fetch(FetchDescriptor<Business>()) { context.delete(item) }
        context.insert(Business.defaultBusiness())
        Service.defaults.forEach(context.insert)
        try context.save()
    }

    @MainActor
    static func deleteAllCustomers(in context: ModelContext) throws -> Int {
        let appointments = try context.fetch(FetchDescriptor<Appointment>())
        appointments.forEach {
            NotificationScheduler.cancel(for: $0)
            context.delete($0)
        }

        let customers = try context.fetch(FetchDescriptor<Customer>())
        customers.forEach(context.delete)

        try context.save()
        return customers.count
    }

    @MainActor
    static func deletePastAppointments(in context: ModelContext, before date: Date = .now) throws -> Int {
        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate { appointment in
                appointment.dateTime < date
            }
        )
        let appointments = try context.fetch(descriptor)
        appointments.forEach {
            NotificationScheduler.cancel(for: $0)
            context.delete($0)
        }

        try context.save()
        return appointments.count
    }
}

struct BackupSnapshot: Codable {
    let version: Int
    let exportedAt: Date
    let businesses: [BusinessRecord]
    let customers: [CustomerRecord]
    let services: [ServiceRecord]
    let appointments: [AppointmentRecord]

    struct BusinessRecord: Codable {
        let id: String
        let name: String
        let category: String
        let phone: String
        let address: String
        let logoUrl: String
        let workingDaysRaw: String
        let openingTime: String
        let closingTime: String
        let appointmentIntervalMinutes: Int
        let createdAt: Date
        let updatedAt: Date
    }

    struct CustomerRecord: Codable {
        let id: String
        let name: String
        let phone: String
        let serviceNotes: String
        let generalNotes: String
        let createdAt: Date
    }

    struct ServiceRecord: Codable {
        let id: String
        let name: String
        let durationMinutes: Int
        let colorHex: String
        let sortOrder: Int
        let price: Double
        let serviceDescription: String
        let isActive: Bool
    }

    struct AppointmentRecord: Codable {
        let id: String
        let customerId: String
        let customerName: String
        let customerPhone: String
        let dateTime: Date
        let durationMinutes: Int
        let serviceIdsJson: String
        let serviceName: String
        let serviceColor: String
        let notes: String
        let statusRaw: String
        let totalPrice: Double
        let staffId: String
        let notificationsEnabled: Bool
        let reminderMinutes: Int
        let startNotificationEnabled: Bool
    }
}

enum BackupService {
    @MainActor
    static func exportData(from context: ModelContext) throws -> Data {
        let businesses = try context.fetch(FetchDescriptor<Business>())
        let customers = try context.fetch(FetchDescriptor<Customer>())
        let services = try context.fetch(FetchDescriptor<Service>())
        let appointments = try context.fetch(FetchDescriptor<Appointment>())

        let snapshot = BackupSnapshot(
            version: 1,
            exportedAt: .now,
            businesses: businesses.map {
                .init(id: $0.id, name: $0.name, category: $0.category, phone: $0.phone, address: $0.address, logoUrl: $0.logoUrl, workingDaysRaw: $0.workingDaysRaw, openingTime: $0.openingTime, closingTime: $0.closingTime, appointmentIntervalMinutes: $0.appointmentIntervalMinutes, createdAt: $0.createdAt, updatedAt: $0.updatedAt)
            },
            customers: customers.map {
                .init(id: $0.id, name: $0.name, phone: $0.phone, serviceNotes: $0.serviceNotes, generalNotes: $0.generalNotes, createdAt: $0.createdAt)
            },
            services: services.map {
                .init(id: $0.id, name: $0.name, durationMinutes: $0.durationMinutes, colorHex: $0.colorHex, sortOrder: $0.sortOrder, price: $0.price, serviceDescription: $0.serviceDescription, isActive: $0.isActive)
            },
            appointments: appointments.map {
                .init(id: $0.id, customerId: $0.customerId, customerName: $0.customerName, customerPhone: $0.customerPhone, dateTime: $0.dateTime, durationMinutes: $0.durationMinutes, serviceIdsJson: $0.serviceIdsJson, serviceName: $0.serviceName, serviceColor: $0.serviceColor, notes: $0.notes, statusRaw: $0.statusRaw, totalPrice: $0.totalPrice, staffId: $0.staffId, notificationsEnabled: $0.notificationsEnabled, reminderMinutes: $0.reminderMinutes, startNotificationEnabled: $0.startNotificationEnabled)
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }

    @MainActor
    static func restoreData(_ data: Data, into context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(BackupSnapshot.self, from: data)

        for item in try context.fetch(FetchDescriptor<Appointment>()) {
            NotificationScheduler.cancel(for: item)
            context.delete(item)
        }
        for item in try context.fetch(FetchDescriptor<Customer>()) { context.delete(item) }
        for item in try context.fetch(FetchDescriptor<Service>()) { context.delete(item) }
        for item in try context.fetch(FetchDescriptor<Business>()) { context.delete(item) }

        snapshot.businesses.forEach {
            let business = Business(id: $0.id, name: $0.name, category: $0.category, phone: $0.phone, address: $0.address, logoUrl: $0.logoUrl, openingTime: $0.openingTime, closingTime: $0.closingTime, appointmentIntervalMinutes: $0.appointmentIntervalMinutes, createdAt: $0.createdAt, updatedAt: $0.updatedAt)
            business.workingDaysRaw = $0.workingDaysRaw
            context.insert(business)
        }
        snapshot.customers.forEach {
            context.insert(Customer(id: $0.id, name: $0.name, phone: $0.phone, serviceNotes: $0.serviceNotes, generalNotes: $0.generalNotes, createdAt: $0.createdAt))
        }
        snapshot.services.forEach {
            context.insert(Service(id: $0.id, name: $0.name, durationMinutes: $0.durationMinutes, colorHex: $0.colorHex, sortOrder: $0.sortOrder, price: $0.price, serviceDescription: $0.serviceDescription, isActive: $0.isActive))
        }
        snapshot.appointments.forEach {
            let appointment = Appointment(id: $0.id, customerId: $0.customerId, customerName: $0.customerName, customerPhone: $0.customerPhone, dateTime: $0.dateTime, durationMinutes: $0.durationMinutes, serviceIds: [], serviceName: $0.serviceName, serviceColor: $0.serviceColor, notes: $0.notes, status: AppointmentStatus(rawValue: $0.statusRaw) ?? .scheduled, totalPrice: $0.totalPrice, staffId: $0.staffId, notificationsEnabled: $0.notificationsEnabled, reminderMinutes: $0.reminderMinutes, startNotificationEnabled: $0.startNotificationEnabled)
            appointment.serviceIdsJson = $0.serviceIdsJson
            context.insert(appointment)
            NotificationScheduler.schedule(for: appointment)
        }
        try context.save()
    }
}

enum ContactImportService {
    @MainActor
    static func importContacts(into context: ModelContext) async throws -> Int {
        let store = CNContactStore()
        let granted = try await store.requestAccess(for: .contacts)
        guard granted else { return 0 }

        let existing = try context.fetch(FetchDescriptor<Customer>()).map(\.phoneDigits)
        var existingSet = Set(existing)
        let keys: [CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var imported = 0

        try store.enumerateContacts(with: request) { contact, _ in
            guard let phone = contact.phoneNumbers.first?.value.stringValue else { return }
            let digits = phone.filter(\.isNumber)
            guard !digits.isEmpty, !existingSet.contains(digits) else { return }
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
            context.insert(Customer(name: name.isEmpty ? phone : name, phone: phone))
            existingSet.insert(digits)
            imported += 1
        }
        try context.save()
        return imported
    }
}

struct WidgetAppointmentSnapshot: Codable, Equatable {
    let generatedAt: Date
    let todayCount: Int
    let completedCount: Int
    let totalRevenue: Double
    let nextCustomerName: String
    let nextServiceName: String
    let nextDate: Date?

    static let empty = WidgetAppointmentSnapshot(generatedAt: .now, todayCount: 0, completedCount: 0, totalRevenue: 0, nextCustomerName: "", nextServiceName: "", nextDate: nil)
}

enum WidgetSnapshotStore {
    static let appGroupId = "group.com.hasanyavuz.randevularim"
    static let snapshotKey = "widget.appointmentSnapshot"

    @MainActor
    static func publish(appointments: [Appointment]) {
        let calendar = Calendar.current
        let todayAppointments = appointments.filter { calendar.isDateInToday($0.dateTime) }
        let activeUpcoming = appointments
            .filter { $0.isActive && $0.dateTime >= .now }
            .sorted { $0.dateTime < $1.dateTime }
        let completedToday = todayAppointments.filter { $0.status == .completed }
        let next = activeUpcoming.first
        let snapshot = WidgetAppointmentSnapshot(
            generatedAt: .now,
            todayCount: todayAppointments.count,
            completedCount: completedToday.count,
            totalRevenue: completedToday.reduce(0) { $0 + $1.totalPrice },
            nextCustomerName: next?.customerName ?? "",
            nextServiceName: next?.serviceName ?? "",
            nextDate: next?.dateTime
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        let defaults = UserDefaults(suiteName: appGroupId) ?? .standard
        defaults.set(data, forKey: snapshotKey)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "RandevularimWidget")
        #endif
    }
}

extension Customer {
    var phoneDigits: String {
        phone.filter(\.isNumber)
    }
}

struct OpenTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Bugünkü Randevuları Aç"
    static var description = IntentDescription("Randevularım uygulamasında bugünkü randevu ekranını açar.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct RandevularimShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTodayIntent(),
            phrases: [
                "\(.applicationName) bugünkü randevuları aç",
                "\(.applicationName) bugün kimler var"
            ],
            shortTitle: "Bugünkü Randevular",
            systemImageName: "calendar"
        )
    }
}

#if canImport(ActivityKit)
enum LiveActivityManager {
    static func start(for appointment: Appointment) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let alreadyRunning = Activity<AppointmentActivityAttributes>.activities
            .contains { $0.attributes.appointmentId == appointment.id }
        guard !alreadyRunning else { return }

        let attributes = AppointmentActivityAttributes(appointmentId: appointment.id)
        let state = AppointmentActivityAttributes.ContentState(
            customerName: appointment.customerName,
            serviceName: appointment.serviceName,
            startDate: appointment.dateTime,
            endDate: appointment.endTime
        )
        try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: appointment.endTime),
            pushType: nil
        )
    }

    static func checkAndSync(appointments: [Appointment]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let now = Date.now
        for appointment in appointments {
            guard appointment.isActive,
                  appointment.dateTime <= now.addingTimeInterval(60),
                  appointment.endTime > now else { continue }
            start(for: appointment)
        }
        Task {
            for activity in Activity<AppointmentActivityAttributes>.activities {
                let apptId = activity.attributes.appointmentId
                let shouldEnd = appointments.first(where: { $0.id == apptId }).map {
                    $0.endTime <= now || !$0.isActive
                } ?? true
                if shouldEnd {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
    }

    static func end(for appointment: Appointment) {
        Task {
            for activity in Activity<AppointmentActivityAttributes>.activities
                where activity.attributes.appointmentId == appointment.id {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    static func endAll() async {
        for activity in Activity<AppointmentActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
#endif

enum NotificationScheduler {
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    static func schedule(for appointment: Appointment) {
        cancel(for: appointment)
        guard appointment.notificationsEnabled || appointment.startNotificationEnabled else { return }

        if appointment.startNotificationEnabled {
            schedule(
                id: startId(for: appointment),
                title: "Randevu Başlıyor",
                body: "\(appointment.customerName) - \(appointment.serviceName)",
                date: appointment.dateTime
            )
        }

        if appointment.notificationsEnabled, appointment.reminderMinutes > 0 {
            let reminderDate = appointment.dateTime.addingTimeInterval(TimeInterval(-appointment.reminderMinutes * 60))
            schedule(
                id: reminderId(for: appointment),
                title: "Randevu Hatırlatması",
                body: "\(appointment.customerName) - \(appointment.serviceName) randevusuna \(appointment.reminderMinutes) dk kaldı.",
                date: reminderDate
            )
        }
    }

    static func cancel(for appointment: Appointment) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            startId(for: appointment),
            reminderId(for: appointment)
        ])
    }

    private static func schedule(id: String, title: String, body: String, date: Date) {
        guard date > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static func startId(for appointment: Appointment) -> String {
        "appointment.\(appointment.id).start"
    }

    private static func reminderId(for appointment: Appointment) -> String {
        "appointment.\(appointment.id).reminder"
    }
}
