import SwiftUI

struct StandingsView: View {
    @State private var selectedLeague = 235
    @State private var rows: [StandingRow] = []
    @State private var isLoading = false
    let leagues = [(id: 235, name: "РПЛ"), (id: 39, name: "АПЛ"), (id: 140, name: "Ла Лига"), (id: 135, name: "Серия А"), (id: 78, name: "Бундеслига")]
    private var currentSeason: Int { let c = Calendar.current; let y = c.component(.year, from: Date()); return c.component(.month, from: Date()) >= 7 ? y : y - 1 }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Лига", selection: $selectedLeague) {
                    ForEach(leagues, id: \.id) { Text($0.name).tag($0.id) }
                }.pickerStyle(.segmented).padding()
                
                if isLoading { Spacer(); ProgressView(); Spacer() }
                else {
                    List(rows) { row in
                        NavigationLink(destination: TeamProfileView(team: row.team)) {
                            HStack(spacing: 8) {
                                Text("\(row.rank)").font(.caption.bold()).frame(width: 24)
                                AsyncImage(url: URL(string: row.team.logo ?? "")) { $0.resizable().scaledToFit() } placeholder: { Color.clear }.frame(width: 20, height: 20)
                                Text(row.team.name).font(.subheadline).lineLimit(1); Spacer()
                                Text("И:\(row.all.played)").font(.caption).foregroundStyle(.secondary)
                                Text("\(row.points)").bold().frame(width: 28)
                            }
                        }
                    }.listStyle(.plain)
                }
            }
            .navigationTitle("Таблицы")
            .task(id: selectedLeague) {
                isLoading = true
                rows = (try? await FootballAPIService.shared.fetchStandings(leagueId: selectedLeague, season: currentSeason)) ?? []
                isLoading = false
            }
        }
    }
}