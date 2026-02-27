import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            APIKeysSettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("API Keys", systemImage: "key")
                }

            SubtitleSettingsView()
                .tabItem {
                    Label("Subtitles", systemImage: "captions.bubble")
                }
        }
        .frame(width: 500, height: 360)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("speechLanguage") private var speechLanguage = "en"
    @AppStorage("translationLanguage") private var translationLanguage = ""
    @AppStorage("audioSource") private var audioSource = "microphone"

    private let speechLanguages = [
        ("en", "English"),
        ("de", "German"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("hi", "Hindi"),
        ("it", "Italian"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("nl", "Dutch"),
        ("pl", "Polish"),
        ("pt", "Portuguese"),
        ("ru", "Russian"),
        ("tr", "Turkish"),
        ("uk", "Ukrainian"),
        ("vi", "Vietnamese"),
    ]

    private let translationLanguages = [
        ("en", "English"),
        ("de", "German"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("hi", "Hindi"),
        ("it", "Italian"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("nl", "Dutch"),
        ("pl", "Polish"),
        ("pt", "Portuguese"),
        ("ru", "Russian"),
        ("tr", "Turkish"),
        ("uk", "Ukrainian"),
        ("vi", "Vietnamese"),
    ]

    @AppStorage("saveTranscript") private var saveTranscript = false
    @AppStorage("saveAudioRecording") private var saveAudioRecording = false
    @AppStorage("saveLocationPath") private var saveLocationPath = ""
    @AppStorage("translationTone") private var translationTone = "casual"

    private let translationTones = [
        ("casual", "Casual"),
        ("professional", "Professional / Formal"),
        ("academic", "Academic"),
    ]

    var body: some View {
        Form {
            Section("Audio") {
                Picker("Audio Source", selection: $audioSource) {
                    Text("Microphone").tag("microphone")
                    Text("System Audio").tag("system")
                }
            }

            Section("Recording") {
                Toggle("Save transcript when recording stops", isOn: $saveTranscript)
                Toggle("Save audio recording", isOn: $saveAudioRecording)

                HStack {
                    Text("Save Location")
                    Spacer()
                    Text(saveLocationDisplay)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Choose...") {
                        chooseSaveLocation()
                    }
                }
            }

            Section("Language") {
                Picker("Speech Language", selection: $speechLanguage) {
                    ForEach(speechLanguages, id: \.0) { code, name in
                        Text(name).tag(code)
                    }
                }

                Picker("Translate To", selection: $translationLanguage) {
                    Text("Off").tag("")
                    ForEach(translationLanguages, id: \.0) { code, name in
                        Text(name).tag(code)
                    }
                }

                if !translationLanguage.isEmpty {
                    Picker("Tone", selection: $translationTone) {
                        ForEach(translationTones, id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }

                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var saveLocationDisplay: String {
        if saveLocationPath.isEmpty {
            return "Documents"
        }
        return URL(fileURLWithPath: saveLocationPath).lastPathComponent
    }

    private func chooseSaveLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose where to save transcripts and recordings"
        panel.prompt = "Select Folder"

        if !saveLocationPath.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: saveLocationPath)
        }

        if panel.runModal() == .OK, let url = panel.url {
            // Store a security-scoped bookmark so we can access this folder later
            if let bookmark = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                UserDefaults.standard.set(bookmark, forKey: "saveLocationBookmark")
            }
            saveLocationPath = url.path
        }
    }
}

// MARK: - API Keys Settings

struct APIKeysSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var deepgramKey = ""
    @State private var anthropicKey = ""
    @State private var saved = false

    var body: some View {
        Form {
            Section {
                SecureField("Deepgram API Key", text: $deepgramKey)
                    .textFieldStyle(.roundedBorder)
                Text("Required for speech-to-text. Get a key at deepgram.com")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                HStack {
                    Text("Deepgram (Required)")
                    if !deepgramKey.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }

            Section {
                SecureField("Anthropic API Key", text: $anthropicKey)
                    .textFieldStyle(.roundedBorder)
                Text("Required for translation. Get a key at console.anthropic.com")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                HStack {
                    Text("Anthropic (For Translation)")
                    if !anthropicKey.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }

            Section {
                Button("Save API Keys") {
                    saveKeys()
                }
                .buttonStyle(.borderedProminent)

                if saved {
                    Text("Keys saved securely to Keychain")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear { loadKeys() }
    }

    private func loadKeys() {
        deepgramKey = SettingsManager.shared.deepgramAPIKey
        anthropicKey = SettingsManager.shared.anthropicAPIKey
    }

    private func saveKeys() {
        SettingsManager.shared.deepgramAPIKey = deepgramKey
        SettingsManager.shared.anthropicAPIKey = anthropicKey
        appState.hasValidAPIKeys = !deepgramKey.isEmpty
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            saved = false
        }
    }
}

// MARK: - Subtitle Settings

struct SubtitleSettingsView: View {
    @AppStorage("subtitleFontSize") private var fontSize = 16.0
    @AppStorage("subtitleOpacity") private var opacity = 0.7
    @AppStorage("subtitleVerticalPosition") private var verticalPosition = "bottom"
    @AppStorage("subtitleHorizontalPosition") private var horizontalPosition = "center"
    @AppStorage("subtitleVisibleBubbles") private var visibleBubbles = 3
    @AppStorage("subtitleFadeOutTime") private var fadeOutTime = 8.0

    var body: some View {
        Form {
            Section("Appearance") {
                Slider(value: $fontSize, in: 12...32, step: 2) {
                    Text("Font Size: \(Int(fontSize))pt")
                }

                Slider(value: $opacity, in: 0.3...1.0, step: 0.1) {
                    Text("Background Opacity: \(Int(opacity * 100))%")
                }
            }

            Section("Display") {
                Picker("Visible Bubbles", selection: $visibleBubbles) {
                    Text("2").tag(2)
                    Text("3").tag(3)
                    Text("4").tag(4)
                    Text("5").tag(5)
                }
                .pickerStyle(.segmented)

                Slider(value: $fadeOutTime, in: 3...30, step: 1) {
                    Text("Fade Out: \(Int(fadeOutTime))s")
                }
            }

            Section("Position") {
                Picker("Vertical", selection: $verticalPosition) {
                    Text("Top").tag("top")
                    Text("Middle").tag("middle")
                    Text("Bottom").tag("bottom")
                }
                .pickerStyle(.segmented)

                Picker("Horizontal", selection: $horizontalPosition) {
                    Text("Left").tag("left")
                    Text("Center").tag("center")
                    Text("Right").tag("right")
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
