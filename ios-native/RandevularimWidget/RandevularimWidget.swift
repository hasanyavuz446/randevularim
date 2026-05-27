import WidgetKit
import SwiftUI

struct WidgetAppointmentSnapshot: Codable {
    let generatedAt: Date
    let todayCount: Int
    let completedCount: Int
    let totalRevenue: Double
    let nextCustomerName: String
    let nextServiceName: String
    let nextDate: Date?
}

struct RandevularimWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetAppointmentSnapshot

    static let placeholder = RandevularimWidgetEntry(
        date: .now,
        snapshot: WidgetAppointmentSnapshot(
            generatedAt: .now,
            todayCount: 0,
            completedCount: 0,
            totalRevenue: 0,
            nextCustomerName: "",
            nextServiceName: "",
            nextDate: nil
        )
    )
}

struct RandevularimWidgetProvider: TimelineProvider {
    private let appGroupId = "group.com.hasanyavuz.randevularim"
    private let snapshotKey = "widget.appointmentSnapshot"

    func placeholder(in context: Context) -> RandevularimWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (RandevularimWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RandevularimWidgetEntry>) -> Void) {
        let entry = loadEntry()
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60))))
    }

    private func loadEntry() -> RandevularimWidgetEntry {
        let defaults = UserDefaults(suiteName: appGroupId) ?? .standard
        guard let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetAppointmentSnapshot.self, from: data) else {
            return .placeholder
        }
        return RandevularimWidgetEntry(date: .now, snapshot: snapshot)
    }
}

struct RandevularimWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RandevularimWidgetEntry

    private var nextLine: String {
        guard let nextDate = entry.snapshot.nextDate, !entry.snapshot.nextCustomerName.isEmpty else {
            return "Yaklaşan randevu yok"
        }
        return "\(entry.snapshot.nextCustomerName) • \(nextDate.formatted(date: .omitted, time: .shortened))"
    }

    var body: some View {
        if family == .systemMedium {
            VStack(alignment: .leading, spacing: 10) {
                header
                HStack(alignment: .top, spacing: 16) {
                    metric(title: "Bugün", value: "\(entry.snapshot.todayCount)")
                    metric(title: "Tamamlandı", value: "\(entry.snapshot.completedCount)")
                    metric(title: "Ciro", value: entry.snapshot.totalRevenue.formatted(.currency(code: "TRY").precision(.fractionLength(0))))
                }
                Divider().overlay(.white.opacity(0.2))
                Text(nextLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if !entry.snapshot.nextServiceName.isEmpty {
                    Text(entry.snapshot.nextServiceName)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(1)
                }
            }
            .containerBackground(Color(red: 0.05, green: 0.05, blue: 0.10), for: .widget)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                header
                Spacer()
                Text("\(entry.snapshot.todayCount)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Bugünkü randevu")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.68))
                Text(nextLine)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .containerBackground(Color(red: 0.05, green: 0.05, blue: 0.10), for: .widget)
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(.yellow)
            Text("Randevularım")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
            Spacer(minLength: 0)
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RandevularimWidget: Widget {
    let kind = "RandevularimWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RandevularimWidgetProvider()) { entry in
            RandevularimWidgetView(entry: entry)
        }
        .configurationDisplayName("Randevularım")
        .description("Bugünkü randevu durumunuzu hızlıca görün.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct RandevularimWidgetBundle: WidgetBundle {
    var body: some Widget {
        RandevularimWidget()
    }
}
