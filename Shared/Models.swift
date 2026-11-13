import Foundation

struct FixturesResponse: Codable { let response: [FixtureItem] }
struct FixtureItem: Codable, Identifiable {
    var id: Int { fixture.id }
    let fixture: FixtureInfo; let league: LeagueInfo; let teams: TeamsPair; let goals: GoalsScore
}
struct FixtureInfo: Codable { let id: Int; let date: String; let status: FixtureStatus }
struct FixtureStatus: Codable { let short: String; let elapsed: Int? }
struct LeagueInfo: Codable, Identifiable { let id: Int; let name: String; let country: String; let logo: String?; let season: Int? }
struct TeamsPair: Codable { let home: TeamInfo; let away: TeamInfo }
struct TeamInfo: Codable, Identifiable { let id: Int; let name: String; let logo: String? }
struct GoalsScore: Codable { let home: Int?; let away: Int? }

struct StandingsResponse: Codable { let response: [StandingsWrapper] }
struct StandingsWrapper: Codable { let league: StandingsLeague }
struct StandingsLeague: Codable { let standings: [[StandingRow]] }
struct StandingRow: Codable, Identifiable {
    var id: Int { team.id }
    let rank: Int; let team: TeamInfo; let points: Int; let goalsDiff: Int; let description: String?; let all: AllStats
}
struct AllStats: Codable { let played: Int; let win: Int; let draw: Int; let lose: Int }

struct EventsResponse: Codable { let response: [MatchEvent] }
struct MatchEvent: Codable, Identifiable {
    var id: String { "\(time.elapsed)-\(player.name ?? "")-\(type)" }
    let time: EventTime; let team: TeamInfo; let player: EventPlayer; let assist: EventPlayer?; let type: String; let detail: String
}
struct EventTime: Codable { let elapsed: Int; let extra: Int? }
struct EventPlayer: Codable { let name: String? }

struct StatisticsResponse: Codable { let response: [TeamStatistics] }
struct TeamStatistics: Codable { let team: TeamInfo; let statistics: [StatItem] }
struct StatItem: Codable, Identifiable { var id: String { type }; let type: String; let value: StatValue? }
enum StatValue: Codable {
    case int(Int), string(String)
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let x = try? c.decode(Int.self) { self = .int(x); return }
        if let x = try? c.decode(String.self) { self = .string(x); return }
        throw DecodingError.typeMismatch(StatValue.self, .init(codingPath: decoder.codingPath, debugDescription: ""))
    }
    var displayString: String { switch self { case .int(let v): return "\(v)"; case .string(let v): return v } }
}
struct LineupsResponse: Codable { let response: [TeamLineup] }
struct TeamLineup: Codable, Identifiable { var id: Int { team.id }; let team: TeamInfo; let formation: String?; let startXI: [LineupPlayerWrapper] }
struct LineupPlayerWrapper: Codable, Identifiable { var id: Int { player.id ?? UUID().hashValue }; let player: LineupPlayer }
struct LineupPlayer: Codable { let id: Int?; let name: String; let number: Int?; let pos: String?; let captain: Bool? }

struct FixturePlayersResponse: Codable { let response: [TeamFixturePlayers] }
struct TeamFixturePlayers: Codable { let team: TeamInfo; let players: [MatchPlayerWrapper] }
struct MatchPlayerWrapper: Codable, Identifiable { var id: Int { player.id }; let player: MatchPlayerBasic; let statistics: [MatchPlayerStats] }
struct MatchPlayerBasic: Codable { let id: Int; let name: String; let photo: String? }
struct MatchPlayerStats: Codable {
    let games: MatchPlayerGames; let shots: MatchPlayerShots?; let goals: MatchPlayerGoals?
    let passes: MatchPlayerPasses?; let duels: MatchPlayerDuels?; let cards: PlayerCardsStats?
}
struct MatchPlayerGames: Codable { let minutes: Int?; let number: Int?; let position: String?; let rating: String?; let captain: Bool? }
struct MatchPlayerShots: Codable { let total: Int?; let on: Int? }
struct MatchPlayerGoals: Codable { let total: Int?; let assists: Int?; let saves: Int? }
struct MatchPlayerPasses: Codable { let total: Int?; let key: Int?; let accuracy: String? }
struct MatchPlayerDuels: Codable { let total: Int?; let won: Int? }

struct PlayerDetailResponse: Codable { let response: [PlayerDetailWrapper] }
struct PlayerDetailWrapper: Codable { let player: PlayerBio; let statistics: [PlayerSeasonStats] }
struct PlayerBio: Codable { let id: Int; let name: String; let firstname: String?; let lastname: String?; let age: Int?; let nationality: String?; let height: String?; let weight: String?; let photo: String? }
struct PlayerSeasonStats: Codable, Identifiable {
    var id: String { "\(league.id)-\(league.season ?? 0)-\(team.id)" }
    let team: TeamInfo; let league: LeagueInfo; let games: PlayerGamesStats; let goals: PlayerGoalsStats; let cards: PlayerCardsStats
}
struct PlayerGamesStats: Codable { let appearences: Int?; let minutes: Int?; let position: String?; let rating: String?; let captain: Bool? }
struct PlayerGoalsStats: Codable { let total: Int?; let assists: Int? }
struct PlayerCardsStats: Codable { let yellow: Int?; let red: Int? }

struct TransfersResponse: Codable { let response: [PlayerTransfersWrapper] }
struct PlayerTransfersWrapper: Codable { let transfers: [TransferItem] }
struct TransferItem: Codable, Identifiable { var id: String { "\(date)-\(teams.inTeam.id)-\(teams.outTeam.id)" }; let date: String; let type: String?; let teams: TransferTeams }
struct TransferTeams: Codable { let inTeam: TeamInfo; let outTeam: TeamInfo; enum CodingKeys: String, CodingKey { case inTeam = "in", outTeam = "out" } }

struct TrophiesResponse: Codable { let response: [TrophyItem] }
struct TrophyItem: Codable, Identifiable { var id: String { "\(league)-\(season)-\(place)" }; let league: String; let country: String; let season: String; let place: String }

struct SquadResponse: Codable { let response: [TeamSquadWrapper] }
struct TeamSquadWrapper: Codable { let players: [SquadPlayer] }
struct SquadPlayer: Codable, Identifiable { let id: Int; let name: String; let age: Int?; let number: Int?; let position: String?; let photo: String? }