import Foundation
import SwiftData

@Model
final class Customer: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var name: String
    var phone: String
    var serviceNotes: String
    var generalNotes: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        phone: String,
        serviceNotes: String = "",
        generalNotes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.serviceNotes = serviceNotes
        self.generalNotes = generalNotes
        self.createdAt = createdAt
    }

    static func == (lhs: Customer, rhs: Customer) -> Bool {
        lhs.id == rhs.id
    }

    var initials: String {
        let parts = name.split(separator: " ")
        if let first = parts.first?.first, let last = parts.dropFirst().last?.first {
            return "\(first)\(last)".uppercased()
        }
        return name.first.map { String($0).uppercased() } ?? "?"
    }
}
