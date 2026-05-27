import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }

            AppointmentListView()
                .tabItem {
                    Label("Randevular", systemImage: "calendar")
                }

            CustomerListView()
                .tabItem {
                    Label("Müşteriler", systemImage: "person.2.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.primary)
    }
}
