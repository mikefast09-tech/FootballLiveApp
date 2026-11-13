import SwiftUI

struct MatchDetailView: View {
    let fixtureItem: FixtureItem
    @State private var selectedTab = 0
    @State private var events: [MatchEvent] = []
    @State private var stats: [TeamStatistics] = []
    @State private var lineups: [TeamLineup] = []
    @State private var matchPlayersStats: [MatchPlayerWrapper] = []
    @State private var selectedMatchPlayer: MatchPlayerWrapper?
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                NavigationLink(destination: TeamProfileView(team: fixtureItem.teams.home)) {
                    VStack {
                        AsyncImage(url: URL(string: fixtureItem.teams.home.logo ?? "")) { $0.resizable().scaledToFit() } placeholder: { Color.clear }.frame(width: 50, height: 50)
                        Text(fixtureItem.teams.home.name).font(.caption.bold()).multilineTextAlignment(.center).foregroundStyle(.primary)
                    }.frame(maxWidth: .infinity)
                }
                VStack(spacing: 4) {
                    Text("\(fixtureItem.goals.home ?? 0) : \(fixtureItem.goals.away ?? 0)").font(.largeTitle.bold())
                    Text(fixtureItem.fixture.status.short).font(.caption).foregroundStyle(.secondary)
                }
                NavigationLink(destination: TeamProfileView(team: fixtureItem.teams.away)) {
                    VStack {
                        AsyncImage(url: URL(string: fixtureItem.teams.away.logo ?? "")) { $0.resizable().scaledToFit() } placeholder: { Color.clear }.frame(width: 50, height: 50)
                        Text(fixtureItem.teams.away.name).font(.caption.bold()).multilineTextAlignment(.center).foregroundStyle(.primary)
                    }.frame(maxWidth: .infinity)
                }
            }.padding().background(Color(.secondarySystemBackground))
            
            Picker("Раздел", selection: $selectedTab) {
                Text("События").tag(0); Text("Статистика").tag(1); Text("Составы").tag(2)
            }.pickerStyle(.segmented).padding()
            
            if isLoading { Spacer(); ProgressView(); Spacer() }
            else {
                List {
                    if selectedTab == 0 {
                        if events.isEmpty { Text("Событий пока нет").foregroundStyle(.secondary) }
                        ForEach(events) { event in
                            HStack {
                                Text("\(event.time.elapsed)'").bold().frame(width: 35, alignment: .leading)
                                Image(systemName: event.type == "Goal" ? "soccerball" : "rectangle.portrait.fill").foregroundStyle(event.detail.contains("Red") ? .red : (event.detail.contains("Yellow") ? .yellow : .primary))
                                VStack(alignment: .leading) {
                                    Text(event.player.name ?? "Игрок").font(.subheadline.bold())
                                    Text("\(event.team.name)  \(event.detail)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else if selectedTab == 1 {
                        if stats.count == 2 {
                            ForEach(stats[0].statistics) { stat in
                                let awayVal = stats[1].statistics.first(where: { $0.type == stat.type })?.value?.displayString ?? "-"
                                HStack {
                                    Text(stat.value?.displayString ?? "-").bold().frame(width: 50, alignment: .leading); Spacer()
                                    Text(stat.type).font(.caption).foregroundStyle(.secondary); Spacer()
                                    Text(awayVal).bold().frame(width: 50, alignment: .trailing)
                                }
                            }
                        } else { Text("Статистика недоступна").foregroundStyle(.secondary) }
                    } else {
                        if lineups.isEmpty { Text("Составы не объявлены").foregroundStyle(.secondary) }
                        ForEach(lineups) { teamLineup in
                            Section("\(teamLineup.team.name) (\(teamLineup.formation ?? "-"))") {
                                ForEach(teamLineup.startXI) { item in
                                    let pStats = matchPlayersStats.first(where: { $0.player.id == item.player.id })
                                    let ratingStr = pStats?.statistics.first?.games.rating
                                    Button { if let pStats = pStats { selectedMatchPlayer = pStats } } label: {
                                        HStack {
                                            Text("\(item.player.number ?? 0)").foregroundStyle(.secondary).frame(width: 25)
                                            Text(item.player.name).foregroundStyle(.primary)
                                            if item.player.captain == true {
                                                Text("К").font(.caption2.bold()).foregroundStyle(.black).frame(width: 18, height: 18).background(Color.yellow, in: Circle())
                                            }
                                            Spacer()
                                            if let r = ratingStr, let val = Double(r), val > 0 {
                                                Text(String(format: "%.1f", val)).font(.caption.bold().monospacedDigit()).foregroundStyle(.white)
                                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                                    .background(val >= 8 ? Color.blue : (val >= 7 ? Color.green : Color.orange), in: Capsule())
                                            } else { Text(item.player.pos ?? "").font(.caption).foregroundStyle(.secondary) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }.listStyle(.plain)
            }
        }
        .navigationTitle(fixtureItem.league.name).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { LiveActivityManager.shared.startMatchActivity(fixture: fixtureItem) } label: { Image(systemName: "platter.filled.top.iphone") }
            }
        }
        .sheet(item: $selectedMatchPlayer) { MatchPlayerDetailSheet(playerWrapper: $0).presentationDetents([.medium, .large]) }
        .task { await loadDetails() }
    }
    
    private func loadDetails() async {
        let id = fixtureItem.fixture.id
        async let ev = try? FootballAPIService.shared.fetchEvents(fixtureId: id)
        async let st = try? FootballAPIService.shared.fetchStatistics(fixtureId: id)
        async let ln = try? FootballAPIService.shared.fetchLineups(fixtureId: id)
        async let pl = try? FootballAPIService.shared.fetchFixturePlayers(fixtureId: id)
        events = await ev ?? []; stats = await st ?? []; lineups = await ln ?? []; matchPlayersStats = await pl ?? []
        isLoading = false
    }
}

struct MatchPlayerDetailSheet: View {
    let playerWrapper: MatchPlayerWrapper
    @Environment(\.dismiss) private var dismiss
    var stat: MatchPlayerStats? { playerWrapper.statistics.first }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        AsyncImage(url: URL(string: playerWrapper.player.photo ?? "")) { $0.resizable().scaledToFill() } placeholder: { Circle().fill(Color.gray.opacity(0.2)) }.frame(width: 56, height: 56).clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(playerWrapper.player.name).font(.headline)
                            Text("Минут на поле: \(stat?.games.minutes ?? 0)'").font(.caption).foregroundStyle(.secondary)
                        }; Spacer()
                        if let r = stat?.games.rating, let val = Double(r), val > 0 {
                            Text(String(format: "%.1f", val)).font(.title3.bold()).foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 4).background(val >= 7.0 ? Color.green : Color.orange, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    NavigationLink(destination: PlayerProfileView(playerId: playerWrapper.player.id, playerName: playerWrapper.player.name)) {
                        Label("Открыть полное досье и карьеру", systemImage: "person.text.rectangle").font(.subheadline.bold()).foregroundStyle(Color.accentColor)
                    }
                }
                Section("Показатели в матче") {
                    InfoRow(title: "Голы / Ассисты", value: "\(stat?.goals?.total ?? 0) / \(stat?.goals?.assists ?? 0)")
                    InfoRow(title: "Удары (в створ)", value: "\(stat?.shots?.total ?? 0) (\(stat?.shots?.on ?? 0))")
                    InfoRow(title: "Передачи (точность)", value: "\(stat?.passes?.total ?? 0) (\(stat?.passes?.accuracy ?? "-")%)")
                    InfoRow(title: "Единоборства (выиграно)", value: "\(stat?.duels?.total ?? 0) (\(stat?.duels?.won ?? 0))")
                    InfoRow(title: "Карточки (ЖК / КК)", value: "\(stat?.cards?.yellow ?? 0) / \(stat?.cards?.red ?? 0)")
                }
            }
            .navigationTitle("Статистика в матче").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Закрыть") { dismiss() } } }
        }
    }
}
