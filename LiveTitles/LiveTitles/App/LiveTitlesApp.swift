import SwiftUI

@main
struct LiveTitlesApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Image("MenuBarIcon")
                    .renderingMode(.template)
                if appState.isRecording {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)
                        .offset(x: 2, y: 2)
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
