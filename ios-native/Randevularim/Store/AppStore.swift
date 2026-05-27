import Foundation
import SwiftData

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
