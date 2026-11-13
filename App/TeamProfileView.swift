import SwiftUI

struct TeamProfileView: View {
    let team: TeamInfo
    @State private var selectedTab = 0
    @State private var allMatches: [FixtureItem] = []
    @State private var squad: [SquadPlayer] = []
    @State private var isLoading = true
    @State private var favorites = FavoritesManager.shared
    
    var lastFiveMatches: [FixtureItem] { allMatches.filter { $0.fixture.status.short == "FT" }.sorted { $0.fixture.date > $1.fixture.date }.prefix(5).reversed() }
    var upcomingMatches: [FixtureItem] { allMatches.filter { $0.fixture.status.short == "NS" }.sorted { $0.fixture.date < $1.fixture.date }.prefix(10).map { $0 } }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                AsyncImage(url: URL(string: team.logo ?? "")) { $0.resizable().scaledToFit() } placeholder: { Color.clear }.frame(width: 64, height: 64)
                Text(team.name).font(.title2.bold())
                if !lastFiveMatches.isEmpty {
                    HStack(spacing: 6) {
                        Text("Форма:").font(.caption).foregroundStyle(.secondary)
                        ForEach(lastFiveMatches) { match in
                            let isHome = match.teams.home.id == team.id
                            let tg = (isHome ? match.goals.home : match.goals.away) ?? 0
                            let og = (isHome ? match.goals.away : match.goals.home) ?? 0
                            Text(tg > og ? "В" : (tg < og ? "П" : "Н")).font(.caption2.bold()).foregroundStyle(.white)
                                .frame(width: 22, height: 22).background(tg > og ? Color.green : (tg < og ? Color.red : Color.gray), in: RoundedRectangle(cornerRadius: 5))
                        }
                    }
                }
            }.padding().frame(maxWidth: .infinity).background(Color(.secondarySystemBackground))
            
            Picker("Раздел", selection: $selectedTab) { Text("Календарь").tag(0); Text("Состав").tag(1) }.pickerStyle(.segmented).padding()
            
            if isLoading { Spacer(); ProgressView(); Spacer() }
            else if selectedTab == 0 {
                List {
                    Section("Предстоящие игры") { ForEach(upcomingMatches) { item in NavigationLink(destination: MatchDetailView(fixtureItem: item)) { MatchRowView(item: item) } } }
                    Section("Последние результаты") { ForEach(lastFiveMatches.reversed()) { item in NavigationLink(destination: MatchDetailView(fixtureItem: item)) { MatchRowView(item: item) } } }
                }.listStyle(.insetGrouped)
            } else {
                List(squad) { player in
                    NavigationLink(destination: PlayerProfileView(playerId: player.id, playerName: player.name)) {
                        HStack(spacing: 12) {
                            Text(player.number != nil ? "\(player.number!)" : "-").font(.subheadline.bold()).foregroundStyle(.secondary).frame(width: 28)
                            AsyncImage(url: URL(string: player.photo ?? "")) { $0.resizable().scaledToFill() } placeholder: { Circle().fill(Color.gray.opacity(0.2)) }.frame(width: 36, height: 36).clipShape(Circle())
                            VStack(alignment: .leading) { Text(player.name).font(.subheadline.bold()); Text(player.position ?? "").font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }.listStyle(.plain)
            }
        }
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { favorites.toggleTeam(team.id) } label: { Image(systemName: favorites.favoriteTeamIDs.contains(team.id) ? "star.fill" : "star").foregroundStyle(.orange) } } }
        .task {
            async let m = try? FootballAPIService.shared.fetchTeamMatches(teamId: team.id)
            async let p = try? FootballAPIService.shared.fetchTeamSquad(teamId: team.id)
            allMatches = await m ?? []; squad = await p ?? []; isLoading = false
        }
    }
}