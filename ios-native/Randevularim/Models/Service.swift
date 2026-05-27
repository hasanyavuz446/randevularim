import SwiftUI
import SwiftData

@Model
final class Service: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var name: String
    var durationMinutes: Int
    var colorHex: String
    var sortOrder: Int
    var price: Double
    var serviceDescription: String
    var isActive: Bool

    var color: Color { Color(hex: colorHex) }

    init(
        id: String = UUID().uuidString,
        name: String,
        durationMinutes: Int,
        colorHex: String,
        sortOrder: Int,
        price: Double = 0,
        serviceDescription: String = "",
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.durationMinutes = durationMinutes
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.price = price
        self.serviceDescription = serviceDescription
        self.isActive = isActive
    }

    static func == (lhs: Service, rhs: Service) -> Bool {
        lhs.id == rhs.id
    }

    static let defaults: [Service] = [
        Service(id: "svc_genel", name: "Genel Randevu", durationMinutes: 30, colorHex: "#5856D6", sortOrder: 0, price: 100),
        Service(id: "svc_danisman", name: "Danışmanlık", durationMinutes: 45, colorHex: "#007AFF", sortOrder: 1, price: 200),
        Service(id: "svc_muayene", name: "Muayene", durationMinutes: 20, colorHex: "#30D158", sortOrder: 2, price: 150),
        Service(id: "svc_egitim", name: "Eğitim / Ders", durationMinutes: 60, colorHex: "#FF2D55", sortOrder: 3, price: 120),
        Service(id: "svc_bakim", name: "Bakım / Uygulama", durationMinutes: 90, colorHex: "#FF9F0A", sortOrder: 4, price: 300),
        Service(id: "svc_diger", name: "Diğer", durationMinutes: 30, colorHex: "#8E8E93", sortOrder: 5, price: 0)
    ]
}
