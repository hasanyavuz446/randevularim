import WidgetKit
import SwiftUI

struct RandevularimWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let subtitle: String
    let count: Int
}

struct RandevularimWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> RandevularimWidgetEntry {
        RandevularimWidgetEntry(date: .now, title: "Bugün", subtitle: "Yaklaşan randevular", count: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (RandevularimWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RandevularimWidgetEntry>) -> Void) {
        let entry = RandevularimWidgetEntry(date: .now, title: "Randevularım", subtitle: "Bugünkü programınızı uygulamada açın", count: 0)
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60))))
    }
}

struct RandevularimWidgetView: View {
    let entry: RandevularimWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.yellow)
                Spacer()
                Text("\(entry.count)")
                    .font(.title.bold())
            }
            Text(entry.title)
                .font(.headline)
            Text(entry.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .containerBackground(Color(red: 0.05, green: 0.05, blue: 0.10), for: .widget)
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
