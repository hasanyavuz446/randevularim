import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @Query(sort: \Customer.name) private var customers: [Customer]

    private var calendar: Calendar { .current }

    private var todayAppointments: [Appointment] {
        appointments.filter { calendar.isDateInToday($0.dateTime) }
    }

    private var thisMonthAppointments: [Appointment] {
        appointments.filter { calendar.isDate($0.dateTime, equalTo: .now, toGranularity: .month) }
    }

    private var completed: [Appointment] {
        appointments.filter { $0.status == .completed }
    }

    private var cancelled: [Appointment] {
        appointments.filter { $0.status == .cancelled }
    }

    private var noShow: [Appointment] {
        appointments.filter { $0.status == .noShow }
    }

    private var upcoming: [Appointment] {
        appointments.filter { $0.dateTime >= .now && $0.isActive }
    }

    private var revenue: Double {
        completed.reduce(0) { $0 + $1.totalPrice }
    }

    private var monthRevenue: Double {
        thisMonthAppointments.filter { $0.status == .completed }.reduce(0) { $0 + $1.totalPrice }
    }

    private var topCustomers: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: appointments, by: \.customerName)
        let mapped: [(String, Int)] = grouped.map { key, value in
            (key, value.count)
        }
        let sorted = mapped.sorted { left, right in
            left.1 == right.1 ? left.0 < right.0 : left.1 > right.1
        }
        return sorted.prefix(5).map { item in
            (name: item.0, count: item.1)
        }
    }

    private var serviceDistribution: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: thisMonthAppointments, by: \.serviceName)
        let mapped: [(String, Int)] = grouped.map { key, value in
            (key, value.count)
        }
        let sorted = mapped.sorted { left, right in
            left.1 == right.1 ? left.0 < right.0 : left.1 > right.1
        }
        return sorted.prefix(5).map { item in
            (name: item.0, count: item.1)
        }
    }

    var body: some View {
        RandevularimScreen(title: "Raporlar") {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricTile(title: "Bugün", value: "\(todayAppointments.count)", systemImage: "calendar", tint: AppTheme.primary)
                        MetricTile(title: "Yaklaşan", value: "\(upcoming.count)", systemImage: "clock.badge.checkmark", tint: AppTheme.accent)
                        MetricTile(title: "Müşteri", value: "\(customers.count)", systemImage: "person.2.fill", tint: AppTheme.primary)
                        MetricTile(title: "Tamamlandı", value: "\(completed.count)", systemImage: "checkmark.circle.fill", tint: AppTheme.success)
                        MetricTile(title: "Ciro", value: revenue.formatted(.currency(code: "TRY").precision(.fractionLength(0))), systemImage: "chart.line.uptrend.xyaxis", tint: AppTheme.warning)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bu Ay")
                            .font(.headline)
                        HStack {
                            reportValue(title: "Randevu", value: "\(thisMonthAppointments.count)")
                            Divider().overlay(.white.opacity(0.12))
                            reportValue(title: "Ciro", value: monthRevenue.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            Divider().overlay(.white.opacity(0.12))
                            reportValue(title: "Ortalama", value: averageRevenueText)
                        }
                    }
                    .padding(16)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Randevu Durumları")
                            .font(.headline)
                        statusLine("Planlanan", count: appointments.filter { $0.status == .scheduled }.count, color: AppTheme.primary)
                        statusLine("Teyit Edilen", count: appointments.filter { $0.status == .confirmed }.count, color: AppTheme.accent)
                        statusLine("Tamamlanan", count: completed.count, color: AppTheme.success)
                        statusLine("İptal", count: cancelled.count, color: AppTheme.danger)
                        statusLine("Gelmedi", count: noShow.count, color: AppTheme.warning)
                    }
                    .padding(16)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    reportList(title: "En Çok Gelen Müşteriler", rows: topCustomers)
                    reportList(title: "Bu Ay Hizmet Dağılımı", rows: serviceDistribution)
                }
                .padding(16)
            }
        }
    }

    private var averageRevenueText: String {
        let completedThisMonth = thisMonthAppointments.filter { $0.status == .completed }
        guard !completedThisMonth.isEmpty else { return "₺0" }
        let average = monthRevenue / Double(completedThisMonth.count)
        return average.formatted(.currency(code: "TRY").precision(.fractionLength(0)))
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

    private func reportValue(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reportList(title: String, rows: [(name: String, count: Int)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            if rows.isEmpty {
                Text("Henüz veri yok")
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(rows, id: \.name) { row in
                    HStack {
                        Text(row.name)
                            .lineLimit(1)
                        Spacer()
                        Text("\(row.count)")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
