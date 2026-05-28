import SwiftUI
import SwiftData
#if canImport(ActivityKit)
import ActivityKit
#endif

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedThemeId") private var selectedThemeId = "night_blue"
    @AppStorage("colorSchemePref") private var colorSchemePref = "dark"
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabsView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .task {
            SeedDataService.seedIfNeeded(in: modelContext)
            await NotificationScheduler.requestAuthorizationIfNeeded()
        }
        .onAppear { applyTheme() }
        .onChange(of: selectedThemeId) { _, _ in applyTheme() }
        .onChange(of: colorSchemePref) { _, _ in applyTheme() }
        .onChange(of: systemColorScheme) { _, _ in applyTheme() }
    }

    private func applyTheme() {
        AppTheme.apply(
            id: selectedThemeId,
            colorSchemePref: colorSchemePref,
            systemColorScheme: systemColorScheme
        )
    }
}

private struct MainTabsView: View {
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @AppStorage("activeTabIndex") private var activeTabIndex = 0

    private func syncLiveActivities() {
        #if canImport(ActivityKit)
        LiveActivityManager.checkAndSync(appointments: appointments)
        #endif
    }

    private var widgetSignature: String {
        appointments
            .map { "\($0.id)|\($0.dateTime.timeIntervalSince1970)|\($0.durationMinutes)|\($0.customerName)|\($0.serviceName)|\($0.statusRaw)|\($0.totalPrice)" }
            .joined(separator: "#")
    }

    var body: some View {
        TabView(selection: $activeTabIndex) {
            HomeView()
                .tabItem { Label("Bugün", systemImage: "house.fill") }
                .tag(0)

            CalendarView()
                .tabItem { Label("Takvim", systemImage: "calendar") }
                .tag(1)

            AppointmentListView()
                .tabItem { Label("Randevular", systemImage: "list.bullet") }
                .tag(2)

            CustomerListView()
                .tabItem { Label("Müşteriler", systemImage: "person.2.fill") }
                .tag(3)

            StatisticsView()
                .tabItem { Label("Raporlar", systemImage: "chart.bar.fill") }
                .tag(4)
        }
        .tint(AppTheme.primary)
        .onAppear {
            WidgetSnapshotStore.publish(appointments: appointments)
            syncLiveActivities()
        }
        .onChange(of: widgetSignature) { _, _ in
            WidgetSnapshotStore.publish(appointments: appointments)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            syncLiveActivities()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            syncLiveActivities()
        }
    }
}

private struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var page = 0

    private let slides = [
        ("calendar.badge.clock", "Randevularım", "Müşteri, hizmet ve randevularınızı iPhone için native hazırlanmış hızlı bir akışta yönetin."),
        ("bell.badge.fill", "Akıllı Hatırlatmalar", "Randevu başlangıcında ve öncesinde bildirim alarak günlük programınızı kaçırmayın."),
        ("chart.bar.fill", "Net Raporlar", "Günlük programı, tamamlanan işleri ve cironuzu tek ekranda takip edin.")
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                TabView(selection: $page) {
                    ForEach(slides.indices, id: \.self) { index in
                        VStack(spacing: 22) {
                            Image(systemName: slides[index].0)
                                .font(.system(size: 64, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                            Text(slides[index].1)
                                .font(.largeTitle.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(slides[index].2)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(.horizontal, 28)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if page == slides.indices.last {
                        onComplete()
                    } else {
                        withAnimation {
                            page += 1
                        }
                    }
                } label: {
                    Text(page == slides.indices.last ? "Başla" : "Devam")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}
