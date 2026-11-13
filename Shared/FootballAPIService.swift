import Foundation

final class FootballAPIService {
    static let shared = FootballAPIService()
    private let baseURL = "https://api-sports.io"
    private let apiKey = "SECRET_API_KEY_PLACEHOLDER"
    private let trackedLeagues = [235, 39, 140, 135, 78, 2]
    
    func makeCachedRequest(endpoint: String, ttl: TimeInterval, forceRefresh: Bool = false) async throws -> Data {
        if !forceRefresh, let cached = APICacheManager.shared.load(forKey: endpoint) { return cached }
        guard let url = URL(string: "\(baseURL)\(endpoint)") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apisports-key")
        let (data, _) = try await URLSession.shared.data(for: request)
        APICacheManager.shared.save(data, forKey: endpoint, ttlSeconds: ttl)
        return data
    }
    
    func fetchFixtures(date: String, isToday: Bool, forceRefresh: Bool = false) async throws -> [FixtureItem] {
        let data = try await makeCachedRequest(endpoint: "/fixtures?date=\(date)&timezone=Europe/Moscow", ttl: isToday ? 60 : 900, forceRefresh: forceRefresh)
        return try JSONDecoder().decode(FixturesResponse.self, from: data).response.filter { trackedLeagues.contains($0.league.id) }
    }
    func fetchStandings(leagueId: Int, season: Int) async throws -> [StandingRow] {
        let data = try await makeCachedRequest(endpoint: "/standings?league=\(leagueId)&season=\(season)", ttl: 3600)
        return try JSONDecoder().decode(StandingsResponse.self, from: data).response.first?.league.standings.first ?? []
    }
    func fetchNextMatchForWidget(teamId: Int) async throws -> FixtureItem? {
        guard teamId != 0 else { return nil }
        let data = try await makeCachedRequest(endpoint: "/fixtures?team=\(teamId)&next=1&timezone=Europe/Moscow", ttl: 300)
        return try JSONDecoder().decode(FixturesResponse.self, from: data).response.first
    }
    func fetchEvents(fixtureId: Int) async throws -> [MatchEvent] {
        let data = try await makeCachedRequest(endpoint: "/fixtures/events?fixture=\(fixtureId)", ttl: 60)
        return try JSONDecoder().decode(EventsResponse.self, from: data).response
    }
    func fetchStatistics(fixtureId: Int) async throws -> [TeamStatistics] {
        let data = try await makeCachedRequest(endpoint: "/fixtures/statistics?fixture=\(fixtureId)", ttl: 60)
        return try JSONDecoder().decode(StatisticsResponse.self, from: data).response
    }
    func fetchLineups(fixtureId: Int) async throws -> [TeamLineup] {
        let data = try await makeCachedRequest(endpoint: "/fixtures/lineups?fixture=\(fixtureId)", ttl: 600)
        return try JSONDecoder().decode(LineupsResponse.self, from: data).response
    }
    func fetchFixturePlayers(fixtureId: Int) async throws -> [MatchPlayerWrapper] {
        let data = try await makeCachedRequest(endpoint: "/fixtures/players?fixture=\(fixtureId)", ttl: 60)
        return try JSONDecoder().decode(FixturePlayersResponse.self, from: data).response.flatMap { $0.players }
    }
    func fetchTopScorers(leagueId: Int, season: Int) async throws -> [PlayerDetailWrapper] {
        let data = try await makeCachedRequest(endpoint: "/players/topscorers?league=\(leagueId)&season=\(season)", ttl: 3600)
        return try JSONDecoder().decode(PlayerDetailResponse.self, from: data).response
    }
    func fetchTopAssists(leagueId: Int, season: Int) async throws -> [PlayerDetailWrapper] {
        let data = try await makeCachedRequest(endpoint: "/players/topassists?league=\(leagueId)&season=\(season)", ttl: 3600)
        return try JSONDecoder().decode(PlayerDetailResponse.self, from: data).response
    }
    func fetchTeamMatches(teamId: Int) async throws -> [FixtureItem] {
        let cal = Calendar.current; let y = cal.component(.year, from: Date())
        let season = cal.component(.month, from: Date()) >= 7 ? y : y - 1
        let data = try await makeCachedRequest(endpoint: "/fixtures?team=\(teamId)&season=\(season)&timezone=Europe/Moscow", ttl: 600)
        return try JSONDecoder().decode(FixturesResponse.self, from: data).response
    }
    func fetchTeamSquad(teamId: Int) async throws -> [SquadPlayer] {
        let data = try await makeCachedRequest(endpoint: "/players/squads?team=\(teamId)", ttl: 86400)
        return try JSONDecoder().decode(SquadResponse.self, from: data).response.first?.players ?? []
    }
    func fetchPlayerProfile(playerId: Int, season: Int) async throws -> PlayerDetailWrapper? {
        let data = try await makeCachedRequest(endpoint: "/players?id=\(playerId)&season=\(season)", ttl: 86400)
        return try JSONDecoder().decode(PlayerDetailResponse.self, from: data).response.first
    }
    func fetchPlayerTransfers(playerId: Int) async throws -> [TransferItem] {
        let data = try await makeCachedRequest(endpoint: "/transfers?player=\(playerId)", ttl: 86400)
        return try JSONDecoder().decode(TransfersResponse.self, from: data).response.first?.transfers ?? []
    }
    func fetchPlayerTrophies(playerId: Int) async throws -> [TrophyItem] {
        let data = try await makeCachedRequest(endpoint: "/trophies?player=\(playerId)", ttl: 86400)
        return try JSONDecoder().decode(TrophiesResponse.self, from: data).response
    }
}
