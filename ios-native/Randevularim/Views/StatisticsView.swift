import SwiftUI
import SwiftData

private enum StatsPeriod: String, CaseIterable {
    case today = "Bugün"
    case week = "Bu Hafta"
    case month = "Bu Ay"
}

struct StatisticsView: View {
    @Query(sort: \Appointment.dateTime) private var appointments: [Appointment]
    @Query(sort: \Customer.name) private var customers: [Customer]
    @State private var period: StatsPeriod = .today

    private let calendar = Calendar.current

    private var filteredAppointments: [Appointment] {
        appointments.filter { isInPeriod($0.dateTime) }
    }

    private var filteredCompleted: [Appointment] {
        filteredAppointments.filter { $0.status == .completed }
    }

    private var filteredRevenue: Double {
        filteredCompleted.reduce(0) { $0 + $1.totalPrice }
    }

    private var allCompleted: [Appointment] {
        appointments.filter { $0.status == .completed }
    }

    private var allRevenue: Double {
        allCompleted.reduce(0) { $0 + $1.totalPrice }
    }

    private var thisMonthAppointments: [Appointment] {
        appointments.filter { calendar.isDate($0.dateTime, equalTo: .now, toGranularity: .month) }
    }

    private var monthRevenue: Double {
        thisMonthAppointments.filter { $0.status == .completed }.reduce(0) { $0 + $1.totalPrice }
    }

    private var upcoming: [Appointment] {
        appointments.filter { $0.dateTime >= .now && $0.isActive }
    }

    private var topCustomers: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: appointments, by: \.customerName)
        let pairs: [(String, Int)] = grouped.map { ($0.key, $0.value.count) }
        let sorted = pairs.sorted { lhs, rhs in lhs.1 == rhs.1 ? lhs.0 < rhs.0 : lhs.1 > rhs.1 }
        return sorted.prefix(5).map { (name: $0.0, count: $0.1) }
    }

    private var serviceDistribution: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: thisMonthAppointments, by: \.serviceName)
        let pairs: [(String, Int)] = grouped.map { ($0.key, $0.value.count) }
        let sorted = pairs.sorted { lhs, rhs in lhs.1 == rhs.1 ? lhs.0 < rhs.0 : lhs.1 > rhs.1 }
        return sorted.prefix(5).map { (name: $0.0, count: $0.1) }
    }

    var body: some View {
        RandevularimScreen(title: "Raporlar") {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    // Period selector
                    periodSelector

                    // Period metrics
                    HStack(spacing: 10) {
                        MetricTile(
                            title: "Randevu",
                            value: "\(filteredAppointments.count)",
                            systemImage: "calendar",
                            tint: AppTheme.primary
                        )
                        MetricTile(
                            title: "Tamamlandı",
                            value: "\(filteredCompleted.count)",
                            systemImage: "checkmark.circle.fill",
                            tint: AppTheme.success
                        )
                        MetricTile(
                            title: "Ciro",
                            value: filteredRevenue.formatted(.currency(code: "TRY").precision(.fractionLength(0))),
                            systemImage: "chart.line.uptrend.xyaxis",
                            tint: AppTheme.warning
                        )
                    }

                    // Quick overview
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        MetricTile(title: "Yaklaşan", value: "\(upcoming.count)", systemImage: "clock.badge.checkmark", tint: AppTheme.accent)
                        MetricTile(title: "Müşteri", value: "\(customers.count)", systemImage: "person.2.fill", tint: AppTheme.primary)
                    }

                    // Bu Ay block
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bu Ay")
                            .font(.headline)
                        HStack {
                            reportValue(title: "Randevu", value: "\(thisMonthAppointments.count)")
                            Rectangle().fill(AppTheme.divider).frame(width: 1)
                            reportValue(title: "Ciro", value: monthRevenue.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                            Rectangle().fill(AppTheme.divider).frame(width: 1)
                            reportValue(title: "Ortalama", value: averageRevenueText)
                        }
                    }
                    .padding(16)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    // Durum dağılımı
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Randevu Durumları")
                            .font(.headline)
                        statusLine("Planlanan", count: appointments.filter { $0.status == .scheduled }.count, color: AppTheme.primary)
                        statusLine("Teyit Edilen", count: appointments.filter { $0.status == .confirmed }.count, color: AppTheme.accent)
                        statusLine("Tamamlanan", count: allCompleted.count, color: AppTheme.success)
                        statusLine("İptal", count: appointments.filter { $0.status == .cancelled }.count, color: AppTheme.danger)
                        statusLine("Gelmedi", count: appointments.filter { $0.status == .noShow }.count, color: AppTheme.warning)
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

    private var periodSelector: some View {
        ThemeSegmentedControl(selection: $period)
    }

    private func isInPeriod(_ date: Date) -> Bool {
        switch period {
        case .today:
            return calendar.isDateInToday(date)
        case .week:
            return calendar.isDate(date, equalTo: .now, toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: .now, toGranularity: .month)
        }
    }

    private var averageRevenueText: String {
        let completedThisMonth = thisMonthAppointments.filter { $0.status == .completed }
        guard !completedThisMonth.isEmpty else { return "₺0" }
        let avg = monthRevenue / Double(completedThisMonth.count)
        return avg.formatted(.currency(code: "TRY").precision(.fractionLength(0)))
    }

    private func statusLine(_ title: String, count: Int, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title)
            Spacer()
            Text("\(count)").foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func reportValue(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.headline.bold())
            Text(title).font(.caption).foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reportList(title: String, rows: [(name: String, count: Int)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            if rows.isEmpty {
                Text("Henüz veri yok").foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(rows, id: \.name) { row in
                    HStack {
                        Text(row.name).lineLimit(1)
                        Spacer()
                        Text("\(row.count)").foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
