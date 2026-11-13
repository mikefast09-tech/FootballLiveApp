import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MatchesView().tabItem { Label("Матчи", systemImage: "sportscourt.fill") }
            LeaguesView().tabItem { Label("Лиги", systemImage: "trophy.fill") }
            StandingsView().tabItem { Label("Таблицы", systemImage: "list.number") }
        }
        .onAppear { NotificationManager.shared.requestAuthorization() }
    }
}