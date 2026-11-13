import SwiftUI

struct LeaguesView: View {
    @State private var selectedLeagueId = 235
    @State private var selectedSection = 0
    @State private var standings: [StandingRow] = []
    @State private var topScorers: [PlayerDetailWrapper] = []
    @State private var topAssists: [PlayerDetailWrapper] = []
    @State private var isLoading = false
    
    let availableLeagues = [(id: 235, name: "РПЛ"), (id: 39, name: "АПЛ"), (id: 140, name: "Ла Лига"), (id: 135, name: "Серия А"), (id: 78, name: "Бундеслига"), (id: 2, name: "Лига Чемпионов")]
    private var currentSeason: Int { let c = Calendar.current; let y = c.component(.year, from: Date()); return c.component(.month, from: Date()) >= 7 ? y : y - 1 }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(availableLeagues, id: \.id) { league in
                            Button { selectedLeagueId = league.id } label: {
                                Text(league.name).font(.subheadline.bold()).padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selectedLeagueId == league.id ? Color.accentColor : Color(.secondarySystemBackground))
                                    .foregroundStyle(selectedLeagueId == league.id ? .white : .primary).clipShape(Capsule())
                            }
                        }
                    }.padding(.horizontal).padding(.vertical, 8)
                }
                Picker("Раздел", selection: $selectedSection) {
                    Text("Таблица").tag(0); Text("Бомбардиры").tag(1); Text("Ассистенты").tag(2)
                }.pickerStyle(.segmented).padding(.horizontal).padding(.bottom, 8)
                
                if isLoading { Spacer(); ProgressView("Загрузка..."); Spacer() }
                else if selectedSection == 0 {
                    List(standings) { row in
                        NavigationLink(destination: TeamProfileView(team: row.team)) {
                            HStack(spacing: 8) {
                                Text("\(row.rank)").font(.caption.bold()).frame(width: 24)
                                AsyncImage(url: URL(string: row.team.logo ?? "")) { $0.resizable().scaledToFit() } placeholder: { Color.clear }.frame(width: 22, height: 22)
                                Text(row.team.name).font(.subheadline).lineLimit(1); Spacer()
                                Text("\(row.points) очк.").font(.subheadline.bold().monospacedDigit())
                            }
                        }
                    }.listStyle(.plain)
                } else {
                    let list = selectedSection == 1 ? topScorers : topAssists
                    List(Array(list.enumerated()), id: \.element.player.id) { index, item in
                        let stat = item.statistics.first
                        NavigationLink(destination: PlayerProfileView(playerId: item.player.id, playerName: item.player.name)) {
                            HStack(spacing: 12) {
                                Text("\(index + 1)").font(.subheadline.bold()).foregroundStyle(.secondary).frame(width: 22)
                                AsyncImage(url: URL(string: item.player.photo ?? "")) { $0.resizable().scaledToFill() } placeholder: { Circle().fill(Color.gray.opacity(0.2)) }.frame(width: 40, height: 40).clipShape(Circle())
                                VStack(alignment: .leading) {
                                    Text(item.player.name).font(.subheadline.bold())
                                    Text("\(stat?.team.name ?? "")  Игр: \(stat?.games.appearences ?? 0)").font(.caption).foregroundStyle(.secondary)
                                }; Spacer()
                                Text("\(selectedSection == 1 ? (stat?.goals.total ?? 0) : (stat?.goals.assists ?? 0))").font(.headline.bold()).foregroundStyle(.tint)
                            }
                        }
                    }.listStyle(.plain)
                }
            }
            .navigationTitle("Лиги")
            .task(id: selectedLeagueId) {
                isLoading = true
                async let st = try? FootballAPIService.shared.fetchStandings(leagueId: selectedLeagueId, season: currentSeason)
                async let sc = try? FootballAPIService.shared.fetchTopScorers(leagueId: selectedLeagueId, season: currentSeason)
                async let asst = try? FootballAPIService.shared.fetchTopAssists(leagueId: selectedLeagueId, season: currentSeason)
                standings = await st ?? []; topScorers = await sc ?? []; topAssists = await asst ?? []; isLoading = false
            }
        }
    }
}
