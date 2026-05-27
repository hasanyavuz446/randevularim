import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Bugün", systemImage: "house.fill")
                }

            CalendarView()
                .tabItem {
                    Label("Takvim", systemImage: "calendar")
                }

            AppointmentListView()
                .tabItem {
                    Label("Randevular", systemImage: "list.bullet")
                }

            CustomerListView()
                .tabItem {
                    Label("Müşteriler", systemImage: "person.2.fill")
                }

            StatisticsView()
                .tabItem {
                    Label("Raporlar", systemImage: "chart.bar.fill")
                }
        }
        .tint(AppTheme.primary)
        .task {
            SeedDataService.seedIfNeeded(in: modelContext)
            await NotificationScheduler.requestAuthorizationIfNeeded()
        }
    }
}
