import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @Query(sort: \Customer.name) private var customers: [Customer]

    private var todayAppointments: [Appointment] {
        appointments.filter { Calendar.current.isDateInToday($0.dateTime) }
    }

    private var completed: [Appointment] {
        appointments.filter { $0.status == .completed }
    }

    private var cancelled: [Appointment] {
        appointments.filter { $0.status == .cancelled }
    }

    private var revenue: Double {
        completed.reduce(0) { $0 + $1.totalPrice }
    }

    var body: some View {
        RandevularimScreen(title: "Raporlar") {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricTile(title: "Bugün", value: "\(todayAppointments.count)", systemImage: "calendar", tint: AppTheme.primary)
                        MetricTile(title: "Müşteri", value: "\(customers.count)", systemImage: "person.2.fill", tint: AppTheme.accent)
                        MetricTile(title: "Tamamlandı", value: "\(completed.count)", systemImage: "checkmark.circle.fill", tint: AppTheme.success)
                        MetricTile(title: "Ciro", value: revenue.formatted(.currency(code: "TRY").precision(.fractionLength(0))), systemImage: "chart.line.uptrend.xyaxis", tint: AppTheme.warning)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Randevu Durumları")
                            .font(.headline)
                        statusLine("Planlanan", count: appointments.filter { $0.status == .scheduled }.count, color: AppTheme.primary)
                        statusLine("Teyit Edilen", count: appointments.filter { $0.status == .confirmed }.count, color: AppTheme.accent)
                        statusLine("Tamamlanan", count: completed.count, color: AppTheme.success)
                        statusLine("İptal", count: cancelled.count, color: AppTheme.danger)
                    }
                    .padding(16)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(16)
            }
        }
    }

    private func statusLine(_ title: String, count: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
            Spacer()
            Text("\(count)")
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}
