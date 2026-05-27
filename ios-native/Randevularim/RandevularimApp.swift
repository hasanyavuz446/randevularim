import SwiftUI
import SwiftData

@main
struct RandevularimApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Business.self, Customer.self, Service.self, Appointment.self)
        } catch {
            fatalError("SwiftData container olusturulamadi: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
