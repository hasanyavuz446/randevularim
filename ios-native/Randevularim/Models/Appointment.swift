import Foundation
import SwiftData

@Model
final class Appointment: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var customerId: String
    var customerName: String
    var customerPhone: String
    var dateTime: Date
    var durationMinutes: Int
    var serviceIdsJson: String
    var serviceName: String
    var serviceColor: String
    var notes: String
    var statusRaw: String
    var totalPrice: Double
    var staffId: String
    var notificationsEnabled: Bool
    var reminderMinutes: Int
    var startNotificationEnabled: Bool

    init(
        id: String = UUID().uuidString,
        customerId: String,
        customerName: String,
        customerPhone: String,
        dateTime: Date,
        durationMinutes: Int,
        serviceIds: [String],
        serviceName: String,
        serviceColor: String,
        notes: String = "",
        status: AppointmentStatus = .scheduled,
        totalPrice: Double = 0,
        staffId: String = "",
        notificationsEnabled: Bool = true,
        reminderMinutes: Int = 30,
        startNotificationEnabled: Bool = true
    ) {
        self.id = id
        self.customerId = customerId
        self.customerName = customerName
        self.customerPhone = customerPhone
        self.dateTime = dateTime
        self.durationMinutes = durationMinutes
        self.serviceIdsJson = (try? String(data: JSONEncoder().encode(serviceIds), encoding: .utf8)) ?? "[]"
        self.serviceName = serviceName
        self.serviceColor = serviceColor
        self.notes = notes
        self.statusRaw = status.rawValue
        self.totalPrice = totalPrice
        self.staffId = staffId
        self.notificationsEnabled = notificationsEnabled
        self.reminderMinutes = reminderMinutes
        self.startNotificationEnabled = startNotificationEnabled
    }

    static func == (lhs: Appointment, rhs: Appointment) -> Bool {
        lhs.id == rhs.id
    }

    var serviceIds: [String] {
        get {
            guard let data = serviceIdsJson.data(using: .utf8),
                  let ids = try? JSONDecoder().decode([String].self, from: data) else {
                return ["svc_genel"]
            }
            return ids
        }
        set {
            serviceIdsJson = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    var status: AppointmentStatus {
        get { AppointmentStatus(rawValue: statusRaw) ?? .scheduled }
        set { statusRaw = newValue.rawValue }
    }

    var endTime: Date {
        dateTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    var isActive: Bool {
        status == .scheduled || status == .confirmed
    }
}
