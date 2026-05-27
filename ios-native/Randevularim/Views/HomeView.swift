import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Business.name) private var businesses: [Business]
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]

    private var business: Business {
        businesses.first ?? Business.defaultBusiness()
    }

    private var todayAppointments: [Appointment] {
        appointments
            .filter { Calendar.current.isDateInToday($0.dateTime) }
            .sorted { $0.dateTime < $1.dateTime }
    }

    private var upcomingAppointments: [Appointment] {
        appointments
            .filter { $0.dateTime >= .now && $0.isActive }
            .sorted { $0.dateTime < $1.dateTime }
    }

    private var completedRevenueToday: Double {
        todayAppointments
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.totalPrice }
    }

    var body: some View {
        RandevularimScreen(title: "Randevularım") {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    businessHeader

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricTile(title: "Bugün planlanan", value: "\(todayAppointments.count)", systemImage: "calendar.badge.clock", tint: AppTheme.primary)
                        MetricTile(title: "Bugünkü ciro", value: currency(completedRevenueToday), systemImage: "chart.line.uptrend.xyaxis", tint: AppTheme.accent)
                    }

                    appointmentSection(
                        title: "Bugünün Programı",
                        appointments: todayAppointments,
                        emptyText: "Bugün randevu yok"
                    )

                    appointmentSection(
                        title: "Sıradaki Diğer Randevular",
                        appointments: Array(upcomingAppointments.filter { !Calendar.current.isDateInToday($0.dateTime) }.prefix(3)),
                        emptyText: "Gelecek randevu bulunmuyor"
                    )
                }
                .padding(16)
            }
        }
    }

    private var businessHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.primary)
                Image(systemName: "calendar")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(business.name)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Profesyonel randevu yönetimi")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func appointmentSection(title: String, appointments: [Appointment], emptyText: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            if appointments.isEmpty {
                Text(emptyText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(16)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                ForEach(appointments) { appointment in
                    AppointmentRow(appointment: appointment)
                }
            }
        }
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "TRY").precision(.fractionLength(0)))
    }
}

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
                        .foregroundStyle(.white)
                    Spacer()
                    Text(appointment.dateTime.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
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
