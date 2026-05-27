import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var business: Business
    @Published var customers: [Customer]
    @Published var services: [Service]
    @Published var appointments: [Appointment]

    init(
        business: Business = .defaultBusiness(),
        customers: [Customer] = [],
        services: [Service] = Service.defaults,
        appointments: [Appointment] = []
    ) {
        self.business = business
        self.customers = customers
        self.services = services
        self.appointments = appointments
    }

    var todayAppointments: [Appointment] {
        appointments
            .filter { Calendar.current.isDateInToday($0.dateTime) }
            .sorted { $0.dateTime < $1.dateTime }
    }

    var upcomingAppointments: [Appointment] {
        appointments
            .filter { $0.dateTime >= .now && $0.isActive }
            .sorted { $0.dateTime < $1.dateTime }
    }

    var completedRevenueToday: Double {
        todayAppointments
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.totalPrice }
    }
}

extension AppStore {
    static var preview: AppStore {
        let customers = [
            Customer(name: "Ayşe Demir", phone: "0555 111 22 33", serviceNotes: "Kısa görüşme tercih ediyor."),
            Customer(name: "Mehmet Kaya", phone: "0555 444 55 66"),
            Customer(name: "Zeynep Arslan", phone: "0555 777 88 99", generalNotes: "WhatsApp hatırlatma gönder.")
        ]

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

        return AppStore(customers: customers, appointments: appointments)
    }
}
