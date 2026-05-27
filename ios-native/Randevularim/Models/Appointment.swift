import Foundation

struct Appointment: Identifiable, Equatable, Codable {
    let id: String
    var customerId: String
    var customerName: String
    var customerPhone: String
    var dateTime: Date
    var durationMinutes: Int
    var serviceIds: [String]
    var serviceName: String
    var serviceColor: String
    var notes: String
    var status: AppointmentStatus
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
        self.serviceIds = serviceIds
        self.serviceName = serviceName
        self.serviceColor = serviceColor
        self.notes = notes
        self.status = status
        self.totalPrice = totalPrice
        self.staffId = staffId
        self.notificationsEnabled = notificationsEnabled
        self.reminderMinutes = reminderMinutes
        self.startNotificationEnabled = startNotificationEnabled
    }

    var endTime: Date {
        dateTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    var isActive: Bool {
        status == .scheduled || status == .confirmed
    }
}
