import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    func requestAuthorization() { UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in } }
    
    func scheduleReminders(for fixtures: [FixtureItem]) {
        let center = UNUserNotificationCenter.current()
        let favTeams = FavoritesManager.shared.favoriteTeamIDs
        let iso = ISO8601DateFormatter()
        for item in fixtures where item.fixture.status.short == "NS" {
            guard favTeams.contains(item.teams.home.id) || favTeams.contains(item.teams.away.id),
                  let matchDate = iso.date(from: item.fixture.date) else { continue }
            let triggerDate = matchDate.addingTimeInterval(-15 * 60)
            guard triggerDate > Date() else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Скоро начало матча!"
            content.body = "\(item.teams.home.name)  \(item.teams.away.name) через 15 минут."
            content.sound = .default
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            center.add(UNNotificationRequest(identifier: "match_\(item.fixture.id)", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
        }
    }
}