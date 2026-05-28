import SwiftUI
import SwiftData

@main
struct RandevularimApp: App {
    let container: ModelContainer
    @AppStorage("selectedThemeId") private var selectedThemeId = "night_blue"
    @AppStorage("colorSchemePref") private var colorSchemePref = "dark"

    init() {
        do {
            container = try ModelContainer(for: Business.self, Customer.self, Service.self, Appointment.self)
        } catch {
            fatalError("SwiftData container olusturulamadi: \(error)")
        }
        let savedTheme = UserDefaults.standard.string(forKey: "selectedThemeId") ?? "night_blue"
        let savedColorScheme = UserDefaults.standard.string(forKey: "colorSchemePref") ?? "dark"
        AppTheme.apply(id: savedTheme, colorSchemePref: savedColorScheme)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(resolvedColorScheme)
        }
        .modelContainer(container)
    }

    private var resolvedColorScheme: ColorScheme? {
        switch colorSchemePref {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
