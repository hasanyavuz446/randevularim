import Foundation

struct Business: Identifiable, Equatable, Codable {
    let id: String
    var name: String
    var category: String
    var phone: String
    var address: String
    var logoUrl: String
    var workingDays: [Int]
    var openingTime: String
    var closingTime: String
    var appointmentIntervalMinutes: Int
    let createdAt: Date
    var updatedAt: Date

    static func defaultBusiness() -> Business {
        Business(
            id: UUID().uuidString,
            name: "İşletmem",
            category: "Genel",
            phone: "",
            address: "",
            logoUrl: "",
            workingDays: [1, 2, 3, 4, 5, 6],
            openingTime: "09:00",
            closingTime: "19:00",
            appointmentIntervalMinutes: 30,
            createdAt: .now,
            updatedAt: .now
        )
    }
}
