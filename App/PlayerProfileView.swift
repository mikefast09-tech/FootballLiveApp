import SwiftUI

struct PlayerProfileView: View {
    let playerId: Int; let playerName: String
    @State private var selectedTab = 0
    @State private var profile: PlayerDetailWrapper?
    @State private var transfers: [TransferItem] = []
    @State private var trophies: [TrophyItem] = []
    @State private var isLoading = true
    
    private var currentSeason: Int { let c = Calendar.current; let y = c.component(.year, from: Date()); return c.component(.month, from: Date()) >= 7 ? y : y - 1 }
    private var wonTrophies: [TrophyItem] { trophies.filter { $0.place.lowercased().contains("winner") } }
    private var seasonSummary: (matches: Int, goals: Int, assists: Int, avgRating: Double?) {
        guard let stats = profile?.statistics else { return (0, 0, 0, nil) }
        let m = stats.reduce(0) { $0 + ($1.games.appearences ?? 0) }
        let g = stats.reduce(0) { $0 + ($1.goals.total ?? 0) }
        let a = stats.reduce(0) { $0 + ($1.goals.assists ?? 0) }
        let r = stats.compactMap { Double($0.games.rating ?? "") }.filter { $0 > 0 }
        return (m, g, a, r.isEmpty ? nil : r.reduce(0, +) / Double(r.count))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                AsyncImage(url: URL(string: profile?.player.photo ?? "")) { $0.resizable().scaledToFill() } placeholder: { Image(systemName: "person.circle.fill").resizable().foregroundStyle(.secondary) }.frame(width: 76, height: 76).clipShape(Circle())
                Text(profile?.player.name ?? playerName).font(.title2.bold())
                if let club = profile?.statistics.first?.team { Text(club.name).font(.subheadline).foregroundStyle(.secondary) }
            }.padding().frame(maxWidth: .infinity).background(Color(.secondarySystemBackground))
            
            Picker("Раздел", selection: $selectedTab) { Text("Сезон и инфо").tag(0); Text("Трансферы").tag(1); Text("Трофеи (\(wonTrophies.count))").tag(2) }.pickerStyle(.segmented).padding()
            
            if isLoading { Spacer(); ProgressView("Загрузка досье..."); Spacer() }
            else {
                List {
                    if selectedTab == 0 {
                        Section("Общая информация") {
                            InfoRow(title: "Национальность", value: profile?.player.nationality ?? "-")
                            InfoRow(title: "Рост / Вес", value: "\(profile?.player.height ?? "-") / \(profile?.player.weight ?? "-")")
                            InfoRow(title: "Позиция", value: profile?.statistics.first?.games.position ?? "-")
                            InfoRow(title: "Рабочая нога", value: "Правая (уточняется)")
                            InfoRow(title: "Трансферная стоимость", value: transfers.first?.type ?? "Нет оценки")
                        }
                        Section("Статистика сезона") {
                            HStack {
                                StatBadge(title: "Матчи", value: "\(seasonSummary.matches)")
                                StatBadge(title: "Голы", value: "\(seasonSummary.goals)")
                                StatBadge(title: "Ассисты", value: "\(seasonSummary.assists)")
                                StatBadge(title: "Оценка", value: seasonSummary.avgRating != nil ? String(format: "%.2f", seasonSummary.avgRating!) : "-", highlight: true)
                            }.padding(.vertical, 4)
                        }
                    } else if selectedTab == 1 {
                        Section("История переходов") {
                            ForEach(transfers) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(item.date)  \(item.type ?? "")").font(.caption).foregroundStyle(.secondary)
                                    Text("\(item.teams.outTeam.name) -> \(item.teams.inTeam.name)").font(.subheadline.bold())
                                }
                            }
                        }
                    } else {
                        Section("Выигранные трофеи") {
                            ForEach(wonTrophies) { trophy in
                                VStack(alignment: .leading) {
                                    Text(trophy.league).font(.subheadline.bold())
                                    Text("\(trophy.country)  \(trophy.season)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }.listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Досье игрока").navigationBarTitleDisplayMode(.inline)
        .task {
            guard playerId != 0 else { isLoading = false; return }
            async let p = try? FootballAPIService.shared.fetchPlayerProfile(playerId: playerId, season: currentSeason)
            async let tr = try? FootballAPIService.shared.fetchPlayerTransfers(playerId: playerId)
            async let tph = try? FootballAPIService.shared.fetchPlayerTrophies(playerId: playerId)
            profile = await p; transfers = await tr ?? []; trophies = await tph ?? []; isLoading = false
        }
    }
}

struct InfoRow: View { let title: String; let value: String; var body: some View { HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text(value).bold() }.font(.subheadline) } }
struct StatBadge: View { let title: String; let value: String; var highlight = false; var body: some View { VStack(spacing: 4) { Text(value).font(.headline.bold()).foregroundStyle(highlight ? .green : .primary); Text(title).font(.caption2).foregroundStyle(.secondary) }.frame(maxWidth: .infinity) } }