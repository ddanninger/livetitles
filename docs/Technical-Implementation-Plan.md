# LiveTitles - Technical Implementation Plan

## Overview

This document defines the Swift/SwiftUI architecture, project structure, dependency management, and implementation roadmap for LiveTitles — a macOS menu bar app for live speech-to-text captioning with movie-style subtitle overlay.

**Target:** macOS 14.0+ (Sonoma), Apple Silicon primary, Intel compatible
**Language:** Swift 5.9+
**UI Framework:** SwiftUI + AppKit (NSPanel for overlay)
**Build System:** Xcode 15+ with Swift Package Manager

---

## 1. Project Structure

```
LiveTitles/
├── LiveTitles.xcodeproj
├── LiveTitles/
│   ├── App/
│   │   ├── LiveTitlesApp.swift          # @main, MenuBarExtra, app lifecycle
│   │   ├── AppState.swift               # Global app state (ObservableObject)
│   │   └── Info.plist                   # LSUIElement=true (no dock icon)
│   │
│   ├── Audio/
│   │   ├── AudioCaptureManager.swift    # Mic + system audio capture
│   │   ├── AudioBufferProcessor.swift   # PCM conversion, chunking for STT
│   │   └── SystemAudioCapture.swift     # ScreenCaptureKit-based system audio
│   │
│   ├── Transcription/
│   │   ├── TranscriptionProvider.swift  # Protocol for STT providers
│   │   ├── DeepgramProvider.swift       # Deepgram Nova-3 WebSocket client
│   │   ├── TranscriptionResult.swift    # Data models (words, speakers, timestamps)
│   │   └── TranscriptionSession.swift   # Session management, reconnection
│   │
│   ├── Speakers/
│   │   ├── SpeakerManager.swift         # Speaker tracking, color assignment
│   │   ├── SpeakerProfile.swift         # Persistent speaker data model
│   │   ├── VoiceFingerprintProvider.swift # Protocol for voice ID
│   │   ├── PicovoiceEagleProvider.swift # Eagle SDK integration
│   │   └── SpeakerMergeLayer.swift      # Map Deepgram labels → Eagle IDs
│   │
│   ├── Translation/
│   │   ├── TranslationProvider.swift    # Protocol for translation providers
│   │   ├── ClaudeTranslationProvider.swift # Anthropic Claude 3.5 Sonnet
│   │   ├── TranslationBuffer.swift      # Sentence buffering before translation
│   │   └── TranslationCache.swift       # LRU cache for repeated phrases
│   │
│   ├── NameExtraction/
│   │   ├── NameExtractor.swift          # Regex-first, LLM fallback
│   │   └── NamePatterns.swift           # Regex patterns for introductions
│   │
│   ├── Overlay/
│   │   ├── SubtitleOverlayWindow.swift  # NSPanel subclass (always-on-top, click-through)
│   │   ├── SubtitleView.swift           # SwiftUI subtitle renderer
│   │   ├── SubtitleLine.swift           # Single line with speaker color + text
│   │   └── SubtitleAnimator.swift       # Fade-in/out, word-by-word animation
│   │
│   ├── UI/
│   │   ├── MenuBarView.swift            # MenuBarExtra content
│   │   ├── SettingsView.swift           # Settings window
│   │   ├── APIKeySetupView.swift        # First-run API key wizard
│   │   ├── SpeakerProfilesView.swift    # Speaker management (V1.1)
│   │   └── SessionHistoryView.swift     # Transcript history (V1.1)
│   │
│   ├── Settings/
│   │   ├── SettingsManager.swift        # UserDefaults + Keychain wrapper
│   │   └── KeychainHelper.swift         # Secure API key storage
│   │
│   ├── Models/
│   │   ├── Subtitle.swift               # Subtitle display model
│   │   ├── Speaker.swift                # Speaker model
│   │   ├── Session.swift                # Captioning session model
│   │   └── APIConfiguration.swift       # API keys and provider config
│   │
│   ├── Networking/
│   │   ├── WebSocketClient.swift        # Generic WebSocket wrapper
│   │   ├── HTTPClient.swift             # Generic HTTP/streaming client
│   │   └── APIError.swift               # Unified error types
│   │
│   ├── Utilities/
│   │   ├── Logger.swift                 # Structured logging
│   │   └── Constants.swift              # App-wide constants
│   │
│   └── Resources/
│       ├── Assets.xcassets              # Menu bar icon, app icon
│       └── LiveTitles.entitlements      # Audio, network entitlements
│
├── LiveTitlesTests/
│   ├── NameExtractorTests.swift
│   ├── TranslationCacheTests.swift
│   ├── SpeakerMergeLayerTests.swift
│   └── AudioBufferProcessorTests.swift
│
└── Package.swift (if using SPM for the app itself)
```

---

## 2. Architecture

### 2.1 App Lifecycle

```swift
// Menu bar-only app — no dock icon, no main window
@main
struct LiveTitlesApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("LiveTitles", systemImage: appState.isRecording ? "captions.bubble.fill" : "captions.bubble") {
            MenuBarView()
                .environmentObject(appState)
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
```

**Key:** `Info.plist` must include `LSUIElement = true` to hide the dock icon.

### 2.2 Data Flow

```
AudioCaptureManager
    │
    ├──► DeepgramProvider (WebSocket)
    │       │
    │       ├──► TranscriptionResult (words + speaker labels + timestamps)
    │       │       │
    │       │       ├──► SpeakerMergeLayer ──► SpeakerManager
    │       │       ├──► NameExtractor ──► SpeakerManager
    │       │       └──► TranslationBuffer ──► ClaudeTranslationProvider
    │       │                                       │
    │       │                                       ▼
    │       │                               Translated text
    │       │
    │       └──► AppState.subtitles ──► SubtitleView (overlay)
    │
    └──► PicovoiceEagleProvider (on-device)
            │
            └──► Speaker embeddings ──► SpeakerMergeLayer
```

### 2.3 Key Design Patterns

- **Protocol-oriented providers**: `TranscriptionProvider`, `TranslationProvider`, `VoiceFingerprintProvider` — swap implementations freely
- **ObservableObject + @Published**: `AppState` drives all UI updates via SwiftUI reactivity
- **Actor-based concurrency**: Audio capture and WebSocket handling use Swift actors for thread safety
- **Combine pipelines**: Stream processing from audio → transcription → translation → display

---

## 3. Key Implementation Details

### 3.1 Menu Bar App (No Dock Icon)

```xml
<!-- Info.plist -->
<key>LSUIElement</key>
<true/>
```

SwiftUI's `MenuBarExtra` (macOS 13+) provides the menu bar icon and dropdown. The `Settings` scene opens via the standard macOS Settings menu item.

### 3.2 Floating Subtitle Overlay

The subtitle overlay is an `NSPanel` configured for always-on-top, click-through behavior:

```swift
class SubtitleOverlayWindow: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        level = .screenSaver          // Always on top
        isOpaque = false
        backgroundColor = .clear
        ignoresMouseEvents = true      // Click-through
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hasShadow = false
    }
}
```

Host a SwiftUI `SubtitleView` inside the panel using `NSHostingView`.

### 3.3 Audio Capture

**Microphone:** `AVAudioEngine` with an input tap on the input node. Request microphone permission via `AVCaptureDevice.requestAccess(for: .audio)`.

**System Audio (macOS 14+):** `ScreenCaptureKit` provides `SCStream` for capturing system audio without needing a virtual audio driver. On macOS 15+, the `SCContentSharingPicker` provides a streamlined permission flow.

```swift
// System audio capture via ScreenCaptureKit
let config = SCStreamConfiguration()
config.capturesAudio = true
config.excludesCurrentProcessAudio = true
config.sampleRate = 16000        // Deepgram expects 16kHz
config.channelCount = 1          // Mono

let filter = SCContentFilter(display: display, excludingWindows: [])
let stream = SCStream(filter: filter, configuration: config, delegate: self)
```

**Audio format for Deepgram:** Linear PCM, 16-bit, 16kHz, mono.

### 3.4 Deepgram WebSocket Integration

Use `URLSessionWebSocketTask` (native, no dependency needed):

```swift
// Connect to Deepgram Nova-3 with diarization
let url = URL(string: "wss://api.deepgram.com/v1/listen?model=nova-3&diarize=true&interim_results=true&punctuate=true&smart_format=true&encoding=linear16&sample_rate=16000")!
var request = URLRequest(url: url)
request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

let task = URLSession.shared.webSocketTask(with: request)
task.resume()
```

**Reconnection:** Exponential backoff (1s, 2s, 4s, 8s, max 30s) with keep-alive pings every 10 seconds.

### 3.5 Translation (Anthropic Claude API)

No official Swift SDK — use `URLSession` with the Messages API:

```swift
// Streaming translation via Anthropic Messages API
var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
request.httpMethod = "POST"
request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

let body: [String: Any] = [
    "model": "claude-3-5-sonnet-20241022",
    "max_tokens": 256,
    "stream": true,
    "system": "Translate the following spoken text to \(targetLanguage). Output only the translation, nothing else.",
    "messages": [["role": "user", "content": text]]
]
```

**Sentence buffering:** Accumulate words until punctuation (. ? !) or a 2-second silence gap, then send the full sentence for translation. This reduces API calls and improves quality.

### 3.6 Secure API Key Storage

Store API keys in the macOS Keychain, not UserDefaults:

```swift
// KeychainHelper — store/retrieve API keys securely
struct KeychainHelper {
    static func save(key: String, service: String) throws { ... }
    static func read(service: String) throws -> String? { ... }
    static func delete(service: String) throws { ... }
}
```

Services: `com.livetitles.deepgram`, `com.livetitles.anthropic`, `com.livetitles.openai`, `com.livetitles.picovoice`

---

## 4. Dependencies

### Swift Package Manager

| Package | Purpose | Source |
|---------|---------|--------|
| **None required for MVP** | Native APIs cover WebSocket, HTTP, audio | — |

**MVP uses zero external dependencies.** All core functionality is achievable with native Apple frameworks:
- `URLSessionWebSocketTask` for Deepgram WebSocket
- `URLSession` with streaming for Anthropic API
- `AVAudioEngine` for microphone capture
- `ScreenCaptureKit` for system audio
- `Security.framework` for Keychain

**Optional (post-MVP):**

| Package | Purpose | When |
|---------|---------|------|
| PicovoiceEagle | Voice fingerprinting | V1.1 (speaker persistence) |

### Frameworks Used (Apple)

| Framework | Purpose |
|-----------|---------|
| SwiftUI | Menu bar UI, settings, overlay content |
| AppKit | NSPanel for floating overlay |
| AVFoundation | Microphone audio capture |
| ScreenCaptureKit | System audio capture (macOS 14+) |
| Security | Keychain for API key storage |
| Combine | Reactive data flow |

---

## 5. Entitlements & Permissions

```xml
<!-- LiveTitles.entitlements -->
<key>com.apple.security.device.audio-input</key>
<true/>

<key>com.apple.security.network.client</key>
<true/>

<!-- For ScreenCaptureKit (system audio) -->
<key>com.apple.security.screen-capture</key>
<true/>

<!-- App Sandbox -->
<key>com.apple.security.app-sandbox</key>
<true/>
```

**Runtime permissions:**
- Microphone access: System prompt on first use
- Screen recording (for system audio): System prompt on first use

---

## 6. Implementation Phases

### Phase 1: Skeleton (Current)
- [x] Project documentation (PRD, AI research)
- [ ] Xcode project setup with correct structure
- [ ] Menu bar app with start/stop toggle
- [ ] Floating subtitle overlay window (static text)
- [ ] Settings window shell

### Phase 2: Live Captioning MVP
- [ ] Microphone audio capture (AVAudioEngine)
- [ ] Deepgram WebSocket integration (Nova-3)
- [ ] Real-time subtitle display (word-by-word)
- [ ] API key setup wizard
- [ ] Basic error handling and reconnection

### Phase 3: Multi-Speaker + Translation
- [ ] Speaker diarization display (colors)
- [ ] Speaker label rendering
- [ ] Claude translation integration
- [ ] Sentence buffering for translation
- [ ] Translation toggle in settings

### Phase 4: Speaker Intelligence (V1.1)
- [ ] Picovoice Eagle integration
- [ ] Speaker merge layer (Deepgram ↔ Eagle)
- [ ] Name extraction (regex + LLM)
- [ ] Persistent speaker profiles
- [ ] Speaker management UI

### Phase 5: Polish (V1.0 Release)
- [ ] Subtitle animations (fade in/out, smooth transitions)
- [ ] System audio capture (ScreenCaptureKit)
- [ ] Session history and export
- [ ] Onboarding flow
- [ ] Error states and user guidance

---

## 7. Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Min macOS version | 14.0 (Sonoma) | ScreenCaptureKit audio, modern SwiftUI APIs |
| WebSocket library | URLSessionWebSocketTask (native) | Zero dependencies, sufficient for Deepgram |
| HTTP client | URLSession (native) | Supports SSE streaming for Claude API |
| UI framework | SwiftUI + NSPanel | SwiftUI for declarative UI, NSPanel for overlay behavior |
| Concurrency | Swift async/await + actors | Modern, safe concurrency for audio + networking |
| API key storage | Keychain | Secure, standard macOS practice |
| Build system | Xcode + SPM | Standard for macOS apps |
| External deps (MVP) | None | Reduces complexity, all needs met by Apple frameworks |

---

*Next: Create Xcode project and implement Phase 1 (skeleton app).*
