import SwiftUI
import WidgetKit

struct MatchesView: View {
    @State private var fixtures: [FixtureItem] = []
    @State private var selectedDayOffset = 0
    @State private var showOnlyFavorites = false
    @State private var isLoading = false
    @State private var favorites = FavoritesManager.shared
    
    private var formattedDate: String {
        let date = Calendar.current.date(byAdding: .day, value: selectedDayOffset, to: Date()) ?? Date()
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"; return df.string(from: date)
    }
    var filteredFixtures: [FixtureItem] {
        guard showOnlyFavorites else { return fixtures }
        return fixtures.filter { favorites.favoriteLeagueIDs.contains($0.league.id) || favorites.favoriteTeamIDs.contains($0.teams.home.id) || favorites.favoriteTeamIDs.contains($0.teams.away.id) }
    }
    var groupedFixtures: [(league: LeagueInfo, games: [FixtureItem])] {
        Dictionary(grouping: filteredFixtures) { $0.league.id }.compactMap { _, items in
            guard let first = items.first else { return nil }
            return (league: first.league, games: items)
        }.sorted { $0.league.name < $1.league.name }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Дата", selection: $selectedDayOffset) {
                    Text("Вчера").tag(-1); Text("Сегодня").tag(0); Text("Завтра").tag(1)
                }.pickerStyle(.segmented).padding(.horizontal).padding(.top, 8)
                
                if isLoading { Spacer(); ProgressView("Загрузка матчей..."); Spacer() }
                else if groupedFixtures.isEmpty {
                    ContentUnavailableView(showOnlyFavorites ? "Нет избранных матчей" : "Матчей нет", systemImage: "sportscourt")
                } else {
                    List {
                        ForEach(groupedFixtures, id: \.league.id) { group in
                            Section {
                                ForEach(group.games) { item in
                                    NavigationLink(destination: MatchDetailView(fixtureItem: item)) { MatchRowView(item: item) }
                                        .swipeActions(edge: .leading) {
                                            Button { favorites.toggleTeam(item.teams.home.id); WidgetCenter.shared.reloadAllTimelines() } label: { Label(item.teams.home.name, systemImage: "star.fill") }.tint(.orange)
                                            Button { favorites.toggleTeam(item.teams.away.id); WidgetCenter.shared.reloadAllTimelines() } label: { Label(item.teams.away.name, systemImage: "star.fill") }.tint(.yellow)
                                        }
                                }
                            } header: {
                                HStack {
                                    Text("\(group.league.country): \(group.league.name)").font(.headline)
                                    Spacer()
                                    Button { favorites.toggleLeague(group.league.id) } label: {
                                        Image(systemName: favorites.favoriteLeagueIDs.contains(group.league.id) ? "star.fill" : "star").foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }.listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Футбол Live")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showOnlyFavorites.toggle() } label: { Label("Только мои", systemImage: showOnlyFavorites ? "star.fill" : "star") }
                        .tint(showOnlyFavorites ? .orange : .primary)
                }
            }
            .task(id: selectedDayOffset) { await loadMatches(force: false) }
            .refreshable { await loadMatches(force: true) }
        }
    }
    private func loadMatches(force: Bool) async {
        isLoading = true
        if let res = try? await FootballAPIService.shared.fetchFixtures(date: formattedDate, isToday: selectedDayOffset == 0, forceRefresh: force) {
            fixtures = res; NotificationManager.shared.scheduleReminders(for: res)
        }
        isLoading = false
    }
}

struct MatchRowView: View {
    let item: FixtureItem
    var isLive: Bool { ["1H", "HT", "2H", "ET", "P"].contains(item.fixture.status.short) }
    var matchTimeText: String {
        if let date = ISO8601DateFormatter().date(from: item.fixture.date) {
            let df = DateFormatter(); df.dateFormat = "HH:mm"; return df.string(from: date)
        }; return "--:--"
    }
    var body: some View {
        HStack {
            VStack {
                if isLive { Text("\(item.fixture.status.elapsed ?? 0)'").font(.caption.bold()).foregroundStyle(.white).padding(.horizontal, 6).padding(.vertical, 2).background(Color.red, in: Capsule()) }
                else if item.fixture.status.short == "FT" { Text("FT").font(.caption.bold()).foregroundStyle(.secondary) }
                else { Text(matchTimeText).font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
            }.frame(width: 48)
            VStack(alignment: .leading, spacing: 6) {
                TeamLine(name: item.teams.home.name, logoURL: item.teams.home.logo)
                TeamLine(name: item.teams.away.name, logoURL: item.teams.away.logo)
            }
            Spacer()
            if item.fixture.status.short != "NS" {
                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(item.goals.home ?? 0)").font(.body.bold())
                    Text("\(item.goals.away ?? 0)").font(.body.bold())
                }
            }
        }.padding(.vertical, 4)
    }
}

struct TeamLine: View {
    let name: String; let logoURL: String?
    var body: some View {
        HStack(spacing: 8) {
            AsyncImage(url: URL(string: logoURL ?? "")) { $0.resizable().scaledToFit() } placeholder: { Circle().fill(Color.gray.opacity(0.2)) }.frame(width: 20, height: 20)
            Text(name).font(.subheadline).lineLimit(1)
        }
    }
}