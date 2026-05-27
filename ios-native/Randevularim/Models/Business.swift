import Foundation
import SwiftData

@Model
final class Business: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var name: String
    var category: String
    var phone: String
    var address: String
    var logoUrl: String
    var workingDaysRaw: String
    var openingTime: String
    var closingTime: String
    var appointmentIntervalMinutes: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        category: String = "Genel",
        phone: String = "",
        address: String = "",
        logoUrl: String = "",
        workingDays: [Int] = [1, 2, 3, 4, 5, 6],
        openingTime: String = "09:00",
        closingTime: String = "19:00",
        appointmentIntervalMinutes: Int = 30,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.phone = phone
        self.address = address
        self.logoUrl = logoUrl
        self.workingDaysRaw = workingDays.map(String.init).joined(separator: ",")
        self.openingTime = openingTime
        self.closingTime = closingTime
        self.appointmentIntervalMinutes = appointmentIntervalMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func defaultBusiness() -> Business {
        Business(
            name: "İşletmem"
        )
    }

    static func == (lhs: Business, rhs: Business) -> Bool {
        lhs.id == rhs.id
    }

    var workingDays: [Int] {
        get {
            workingDaysRaw
                .split(separator: ",")
                .compactMap { Int($0) }
        }
        set {
            workingDaysRaw = newValue.map(String.init).joined(separator: ",")
        }
    }
}
