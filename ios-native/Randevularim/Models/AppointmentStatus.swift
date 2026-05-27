import Foundation

enum AppointmentStatus: String, CaseIterable, Identifiable, Codable {
    case scheduled
    case confirmed
    case completed
    case cancelled
    case noShow

    var id: String { rawValue }

    var label: String {
        switch self {
        case .scheduled: "Planlandı"
        case .confirmed: "Teyit Edildi"
        case .completed: "Tamamlandı"
        case .cancelled: "İptal Edildi"
        case .noShow: "Gelmedi"
        }
    }
}
