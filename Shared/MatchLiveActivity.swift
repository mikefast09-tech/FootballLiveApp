import ActivityKit
import WidgetKit
import SwiftUI

struct MatchActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable { var homeScore: Int; var awayScore: Int; var elapsed: Int; var statusShort: String }
    var homeTeamName: String; var awayTeamName: String; var leagueName: String
}

final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<MatchActivityAttributes>?
    
    func startMatchActivity(fixture: FixtureItem) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attr = MatchActivityAttributes(homeTeamName: fixture.teams.home.name, awayTeamName: fixture.teams.away.name, leagueName: fixture.league.name)
        let state = MatchActivityAttributes.ContentState(homeScore: fixture.goals.home ?? 0, awayScore: fixture.goals.away ?? 0, elapsed: fixture.fixture.status.elapsed ?? 0, statusShort: fixture.fixture.status.short)
        currentActivity = try? Activity.request(attributes: attr, content: ActivityContent(state: state, staleDate: nil))
    }
}

struct MatchLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MatchActivityAttributes.self) { context in
            HStack {
                Text(context.attributes.homeTeamName).font(.headline).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 2) {
                    Text("\(context.state.homeScore) : \(context.state.awayScore)").font(.title2.bold())
                    Text("\(context.state.elapsed)'  LIVE").font(.caption2.bold()).foregroundStyle(.red)
                }
                Text(context.attributes.awayTeamName).font(.headline).lineLimit(1).frame(maxWidth: .infinity, alignment: .trailing)
            }.padding().activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Text(context.attributes.homeTeamName).font(.caption.bold()).lineLimit(1) }
                DynamicIslandExpandedRegion(.trailing) { Text(context.attributes.awayTeamName).font(.caption.bold()).lineLimit(1) }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("\(context.state.homeScore) : \(context.state.awayScore)").font(.title3.bold())
                        Text("\(context.state.elapsed)'  \(context.attributes.leagueName)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            } compactLeading: { Text("\(context.attributes.homeTeamName.prefix(3).uppercased()) \(context.state.homeScore)").font(.caption2.bold()) }
            compactTrailing: { Text("\(context.state.awayScore) \(context.attributes.awayTeamName.prefix(3).uppercased())").font(.caption2.bold()) }
            minimal: { Text("\(context.state.homeScore):\(context.state.awayScore)").font(.caption2.bold()) }
        }
    }
}