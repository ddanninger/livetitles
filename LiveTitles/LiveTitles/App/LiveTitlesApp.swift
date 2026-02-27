import SwiftUI

@main
struct LiveTitlesApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Label("LiveTitles", systemImage: appState.isRecording ? "captions.bubble.fill" : "captions.bubble")
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
