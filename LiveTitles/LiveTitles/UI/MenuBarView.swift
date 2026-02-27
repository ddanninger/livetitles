import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("translationLanguage") private var translationLanguage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Status
            statusSection

            Divider()

            // Start / Stop
            Button(action: { appState.toggleRecording() }) {
                Label(
                    appState.isRecording ? "Stop Captioning" : "Start Captioning",
                    systemImage: appState.isRecording ? "stop.fill" : "play.fill"
                )
            }
            .keyboardShortcut("r", modifiers: [.command])
            .padding(.horizontal, 4)
            .padding(.vertical, 2)

            Divider()

            // Translation toggle (only if Anthropic key is set and target language chosen)
            if !SettingsManager.shared.anthropicAPIKey.isEmpty && !translationLanguage.isEmpty {
                Toggle("Translation", isOn: $appState.isTranslationEnabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)

                Divider()
            }

            // Settings
            SettingsLink {
                Label("Settings...", systemImage: "gear")
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)

            // API Keys warning
            if !appState.hasValidAPIKeys {
                Divider()
                SettingsLink {
                    Label("Set Up API Keys", systemImage: "key.fill")
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }

            Divider()

            // Quit
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label("Quit LiveTitles", systemImage: "xmark.circle")
            }
            .keyboardShortcut("q", modifiers: [.command])
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .frame(width: 220)
    }

    @ViewBuilder
    private var statusSection: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var statusColor: Color {
        switch appState.connectionState {
        case .connected:
            return .red
        case .connecting, .reconnecting:
            return .orange
        case .disconnected:
            return .gray
        }
    }

    private var statusText: String {
        if !appState.isRecording {
            return "Idle"
        }
        switch appState.connectionState {
        case .connected:
            return "Recording"
        case .connecting:
            return "Connecting..."
        case .reconnecting:
            return "Reconnecting..."
        case .disconnected:
            return "Starting..."
        }
    }
}
