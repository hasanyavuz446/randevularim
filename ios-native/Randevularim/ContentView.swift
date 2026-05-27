import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

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
    }
}

private struct MainTabsView: View {
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]

    private var widgetSignature: String {
        appointments
            .map { "\($0.id)|\($0.dateTime.timeIntervalSince1970)|\($0.durationMinutes)|\($0.customerName)|\($0.serviceName)|\($0.statusRaw)|\($0.totalPrice)" }
            .joined(separator: "#")
    }

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
        .onAppear {
            WidgetSnapshotStore.publish(appointments: appointments)
        }
        .onChange(of: widgetSignature) { _, _ in
            WidgetSnapshotStore.publish(appointments: appointments)
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
                                .foregroundStyle(.white)
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
