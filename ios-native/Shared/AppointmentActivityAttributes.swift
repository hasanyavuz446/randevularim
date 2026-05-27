import Foundation
#if canImport(ActivityKit)
import ActivityKit

struct AppointmentActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var customerName: String
        var serviceName: String
        var startDate: Date
        var endDate: Date
    }

    var appointmentId: String
}
#endif
