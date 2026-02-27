import SwiftUI

@main
struct LiveTitlesApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
