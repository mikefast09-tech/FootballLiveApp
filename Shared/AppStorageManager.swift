import Foundation
import SwiftUI

@Observable
final class FavoritesManager {
    static let shared = FavoritesManager()
    private let defaults = UserDefaults(suiteName: "group.com.yourname.footballlive") ?? .standard
    var favoriteTeamIDs: Set<Int> { didSet { defaults.set(Array(favoriteTeamIDs), forKey: "favTeams") } }
    var favoriteLeagueIDs: Set<Int> { didSet { defaults.set(Array(favoriteLeagueIDs), forKey: "favLeagues") } }
    var primaryWidgetTeamID: Int { didSet { defaults.set(primaryWidgetTeamID, forKey: "widgetTeamID") } }
    
    init() {
        self.favoriteTeamIDs = Set(defaults.array(forKey: "favTeams") as? [Int] ?? [])
        self.favoriteLeagueIDs = Set(defaults.array(forKey: "favLeagues") as? [Int] ?? [])
        self.primaryWidgetTeamID = defaults.integer(forKey: "widgetTeamID")
    }
    func toggleTeam(_ id: Int) {
        if favoriteTeamIDs.contains(id) { favoriteTeamIDs.remove(id) }
        else { favoriteTeamIDs.insert(id); if primaryWidgetTeamID == 0 { primaryWidgetTeamID = id } }
    }
    func toggleLeague(_ id: Int) {
        if favoriteLeagueIDs.contains(id) { favoriteLeagueIDs.remove(id) } else { favoriteLeagueIDs.insert(id) }
    }
}

final class APICacheManager {
    static let shared = APICacheManager()
    private let defaults = UserDefaults(suiteName: "group.com.yourname.footballlive") ?? .standard
    private struct CacheEntry: Codable { let data: Data; let expiry: Date }
    
    func save(_ data: Data, forKey key: String, ttlSeconds: TimeInterval) {
        if let encoded = try? JSONEncoder().encode(CacheEntry(data: data, expiry: Date().addingTimeInterval(ttlSeconds))) {
            defaults.set(encoded, forKey: "cache_\(key)")
        }
    }
    func load(forKey key: String) -> Data? {
        guard let raw = defaults.data(forKey: "cache_\(key)"),
              let entry = try? JSONDecoder().decode(CacheEntry.self, from: raw) else { return nil }
        if Date() < entry.expiry { return entry.data }
        defaults.removeObject(forKey: "cache_\(key)"); return nil
    }
}