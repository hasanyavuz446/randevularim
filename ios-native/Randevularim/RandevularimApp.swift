import SwiftUI

@main
struct RandevularimApp: App {
    @StateObject private var store = AppStore.preview

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
