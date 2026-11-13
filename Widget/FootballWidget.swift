import WidgetKit
import SwiftUI

struct MatchWidgetEntry: TimelineEntry { let date: Date; let fixture: FixtureItem? }

struct MatchTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MatchWidgetEntry { MatchWidgetEntry(date: Date(), fixture: nil) }
    func getSnapshot(in context: Context, completion: @escaping (MatchWidgetEntry) -> Void) { completion(MatchWidgetEntry(date: Date(), fixture: nil)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MatchWidgetEntry>) -> Void) {
        Task {
            let nextMatch = try? await FootballAPIService.shared.fetchNextMatchForWidget(teamId: FavoritesManager.shared.primaryWidgetTeamID)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
            completion(Timeline(entries: [MatchWidgetEntry(date: Date(), fixture: nextMatch)], policy: .after(nextUpdate)))
        }
    }
}

struct FootballWidgetEntryView: View {
    var entry: MatchWidgetEntry
    @Environment(\.widgetFamily) var family
    var body: some View {
        if let match = entry.fixture {
            VStack(alignment: .leading, spacing: 2) {
                Text(match.league.name).font(.caption2.bold()).foregroundStyle(.secondary)
                HStack { Text(match.teams.home.name).lineLimit(1); Spacer(); Text(match.goals.home != nil ? "\(match.goals.home!)" : "-").bold() }.font(.caption)
                HStack { Text(match.teams.away.name).lineLimit(1); Spacer(); Text(match.goals.away != nil ? "\(match.goals.away!)" : "-").bold() }.font(.caption)
            }
        } else { Text("Выберите клуб в приложении").font(.caption2) }
    }
}

struct FootballWidget: Widget {
    let kind: String = "FootballWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MatchTimelineProvider()) { entry in
            FootballWidgetEntryView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Ближайший матч")
        .description("Счет и расписание любимого клуба.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    }
}

@main
struct FootballWidgetsBundle: WidgetBundle {
    var body: some Widget { FootballWidget(); MatchLiveActivityWidget() }
}