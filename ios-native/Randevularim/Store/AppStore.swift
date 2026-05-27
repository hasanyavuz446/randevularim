import Foundation
import SwiftData
import UserNotifications

enum SeedDataService {
    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let businessCount = (try? context.fetchCount(FetchDescriptor<Business>())) ?? 0
        if businessCount == 0 {
            context.insert(Business.defaultBusiness())
        }

        let serviceCount = (try? context.fetchCount(FetchDescriptor<Service>())) ?? 0
        if serviceCount == 0 {
            Service.defaults.forEach(context.insert)
        }

        let customerCount = (try? context.fetchCount(FetchDescriptor<Customer>())) ?? 0
        if customerCount == 0 {
            seedPreviewFlow(in: context)
        }

        try? context.save()
    }

    @MainActor
    private static func seedPreviewFlow(in context: ModelContext) {
        let customers = [
            Customer(name: "Ayşe Demir", phone: "0555 111 22 33", serviceNotes: "Kısa görüşme tercih ediyor."),
            Customer(name: "Mehmet Kaya", phone: "0555 444 55 66"),
            Customer(name: "Zeynep Arslan", phone: "0555 777 88 99", generalNotes: "WhatsApp hatırlatma gönder.")
        ]
        customers.forEach(context.insert)

        let appointments = [
            Appointment(
                customerId: customers[0].id,
                customerName: customers[0].name,
                customerPhone: customers[0].phone,
                dateTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: .now) ?? .now,
                durationMinutes: 45,
                serviceIds: ["svc_danisman"],
                serviceName: "Danışmanlık",
                serviceColor: "#007AFF",
                status: .confirmed,
                totalPrice: 200
            ),
            Appointment(
                customerId: customers[1].id,
                customerName: customers[1].name,
                customerPhone: customers[1].phone,
                dateTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: .now) ?? .now,
                durationMinutes: 30,
                serviceIds: ["svc_genel"],
                serviceName: "Genel Randevu",
                serviceColor: "#5856D6",
                totalPrice: 100
            ),
            Appointment(
                customerId: customers[2].id,
                customerName: customers[2].name,
                customerPhone: customers[2].phone,
                dateTime: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now,
                durationMinutes: 60,
                serviceIds: ["svc_egitim"],
                serviceName: "Eğitim / Ders",
                serviceColor: "#FF2D55",
                totalPrice: 120
            )
        ]
        appointments.forEach(context.insert)
    }
}

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
