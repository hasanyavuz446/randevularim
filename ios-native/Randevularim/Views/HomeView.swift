import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.openURL) private var openURL
    @Query(sort: \Business.name) private var businesses: [Business]
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @AppStorage("activeTabIndex") private var activeTabIndex = 0
    @State private var isShowingForm = false

    private var business: Business { businesses.first ?? Business.defaultBusiness() }

    private var todayAppointments: [Appointment] {
        appointments.filter { Calendar.current.isDateInToday($0.dateTime) }.sorted { $0.dateTime < $1.dateTime }
    }

    private var featuredAppointment: Appointment? {
        appointments.first { $0.isActive && $0.endTime > .now && Calendar.current.isDateInToday($0.dateTime) }
    }

    private var upcomingOther: [Appointment] {
        let featuredId = featuredAppointment?.id
        return appointments
            .filter { $0.isActive && $0.endTime > .now && $0.id != featuredId }
            .prefix(4)
            .sorted { $0.dateTime < $1.dateTime }
    }

    private var completedRevenueToday: Double {
        todayAppointments.filter { $0.status == .completed }.reduce(0) { $0 + $1.totalPrice }
    }

    private var noShowCount: Int {
        todayAppointments.filter { $0.status == .noShow }.count
    }

    private var activeCount: Int {
        todayAppointments.filter { $0.isActive }.count
    }

    var body: some View {
        RandevularimScreen(title: "Randevularım") {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    businessHeader

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        Button { activeTabIndex = 2 } label: {
                            MetricTile(title: "Bugün planlanan", value: "\(activeCount)", systemImage: "calendar.badge.clock", tint: AppTheme.primary)
                        }
                        .buttonStyle(.plain)
                        Button { activeTabIndex = 4 } label: {
                            MetricTile(title: "Bugünkü ciro", value: currency(completedRevenueToday), systemImage: "chart.line.uptrend.xyaxis", tint: AppTheme.accent)
                        }
                        .buttonStyle(.plain)
                    }

                    if noShowCount > 0 {
                        Label("\(noShowCount) müşteri bugün gelmedi olarak işaretlendi.", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.warning)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    }

                    if let featured = featuredAppointment {
                        sectionHeader("Sıradaki Randevu")
                        HeroAppointmentCard(appointment: featured, openURL: openURL)
                    }

                    if !upcomingOther.isEmpty {
                        sectionHeader("Sıradaki Diğer Randevular")
                        ForEach(Array(upcomingOther.prefix(4))) { appt in
                            NavigationLink {
                                AppointmentDetailView(appointment: appt)
                            } label: {
                                AppointmentRow(appointment: appt)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if featuredAppointment == nil && upcomingOther.isEmpty {
                        Text("Sırada bekleyen randevu yok.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(16)
                .padding(.bottom, 80)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { SettingsView() } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button { isShowingForm = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Randevu Ekle")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(AppTheme.primary, in: Capsule())
                    .shadow(color: AppTheme.primary.opacity(0.4), radius: 8, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $isShowingForm) {
            AppointmentFormView()
        }
    }

    private var businessHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: [AppTheme.primary, AppTheme.primary.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "calendar")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(business.name)
                    .font(.title2.bold())
                Text(Date.now.formatted(.dateTime.day().month(.wide).weekday(.wide).locale(Locale(identifier: "tr_TR"))))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(.headline)
    }

    private func appointmentSection(title: String, appointments: [Appointment], emptyText: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            if appointments.isEmpty {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                ForEach(appointments) { appt in
                    NavigationLink { AppointmentDetailView(appointment: appt) } label: { AppointmentRow(appointment: appt) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "TRY").precision(.fractionLength(0)))
    }
}

// MARK: - Hero Card

private struct HeroAppointmentCard: View {
    let appointment: Appointment
    let openURL: OpenURLAction

    private var businessName: String { "Randevularım" }

    var body: some View {
        NavigationLink {
            AppointmentDetailView(appointment: appointment)
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(appointment.dateTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(appointment.customerName)
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text(appointment.serviceName)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.68))

                    Spacer(minLength: 12)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(appointment.durationMinutes) dk")
                            .font(.caption)
                        Text("·")
                        Text(appointment.totalPrice.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.56))
                }

                Spacer()

                VStack(spacing: 10) {
                    heroActionButton(systemImage: "phone.fill") {
                        let digits = appointment.customerPhone.filter(\.isNumber)
                        openURL(URL(string: "tel://\(digits)")!)
                    }
                    heroActionButton(systemImage: "message.fill") {
                        let digits = appointment.customerPhone.filter(\.isNumber)
                        let normalized = digits.hasPrefix("0") ? "9\(digits)" : "90\(digits)"
                        let dateStr = appointment.dateTime.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "tr_TR")))
                        let timeStr = appointment.dateTime.formatted(date: .omitted, time: .shortened)
                        let msg = "Merhaba \(appointment.customerName), \(dateStr) saat \(timeStr) randevunuz olduğunu hatırlatmak isteriz. Görüşmek üzere!"
                        let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        openURL(URL(string: "https://wa.me/\(normalized)?text=\(encoded)")!)
                    }
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [AppTheme.primary.opacity(0.9), AppTheme.primary.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(AppTheme.primary.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func heroActionButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.15), in: Circle())
        }
    }
}

// MARK: - AppointmentRow

struct AppointmentRow: View {
    let appointment: Appointment

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: appointment.serviceColor))
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(appointment.customerName)
                        .font(.headline)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(appointment.dateTime.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                        if !Calendar.current.isDateInToday(appointment.dateTime) {
                            Text(appointment.dateTime.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "tr_TR"))))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                Text("\(appointment.serviceName) · \(appointment.durationMinutes) dk")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(minHeight: 58)
        .padding(12)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
