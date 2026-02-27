# LiveTitles

A native macOS menu bar app that displays real-time, movie-style subtitles for any conversation — video calls, in-person meetings, or any audio source.

![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Live Speech-to-Text** — Real-time transcription powered by Deepgram Nova-3 with sub-300ms latency
- **Live Translation** — Translate conversations in real-time into 15+ languages using Claude 3.5 Sonnet
- **Translation Tone** — Choose casual, professional, or academic tone for proper honorifics (Korean, Japanese, etc.)
- **Floating Subtitle Overlay** — Cinema-style subtitles that float above all windows, click-through and always visible
- **Menu Bar Only** — No dock icon, no app window — just floating subtitles and menu bar controls
- **Save Transcripts** — Export conversations as Markdown files with speaker labels and translations
- **Audio Recording** — Optionally save the full audio alongside the transcript
- **Configurable** — Adjust subtitle position, font size, opacity, save location, and more

## How It Works

```
Microphone / System Audio
        ↓
  Deepgram Nova-3 (WebSocket) → Real-time transcription
        ↓
  Claude Translation (optional) → Translated text with tone/honorific control
        ↓
  Floating Overlay → Cinema-style subtitles on screen
        ↓
  Save to Disk (optional) → Markdown transcript + audio recording
```

## Prerequisites

- **macOS 14.0+** (Sonoma)
- **Xcode 15+**
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** — Install via `brew install xcodegen`
- **Deepgram API key** — [Sign up](https://console.deepgram.com) (free tier includes $200 credits)
- **Anthropic API key** *(optional, for translation)* — [Sign up](https://console.anthropic.com)

## Getting Started

```bash
# Clone the repository
git clone git@github.com:ddanninger/livetitles.git
cd livetitles

# Generate Xcode project
cd LiveTitles
xcodegen generate

# Open in Xcode
open LiveTitles.xcodeproj
```

Build and run with **⌘R** in Xcode.

On first launch, enter your API keys via the menu bar → **Settings**.

### Configuration

In **Settings → General**:

- **Speech Language** — Pick the language being spoken
- **Translate To** — Choose a target language (or "Off")
- **Tone** — Casual, Professional, or Academic (controls honorifics in Korean, Japanese, etc.)
- **Save Transcript** — Auto-save a Markdown file when recording stops
- **Save Audio Recording** — Save the full audio as a `.caf` file
- **Save Location** — Choose where transcripts and recordings are saved

### Permissions

The app will request:
- **Microphone access** — for capturing speech
- **Screen recording** — for system audio capture (optional)

## Project Structure

```
LiveTitles/
├── App/                 # Entry point, global state
├── Audio/               # Mic + system audio capture
├── Transcription/       # Deepgram WebSocket integration
├── Speakers/            # Speaker tracking & color assignment
├── Translation/         # Claude translation pipeline
├── NameExtraction/      # Speaker name detection
├── Overlay/             # NSPanel floating subtitle window
├── UI/                  # Menu bar & settings views
├── Settings/            # Keychain-based settings manager
├── Models/              # Data models
├── Networking/          # WebSocket & HTTP clients
└── Utilities/           # Constants, logging
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 5.9 |
| UI | SwiftUI + AppKit (NSPanel) |
| Speech-to-Text | Deepgram Nova-3 (WebSocket) |
| Translation | Anthropic Claude 3.5 Sonnet |
| Audio Capture | AVAudioEngine + ScreenCaptureKit |
| API Key Storage | macOS Keychain |
| Dependencies | None (all native Apple frameworks) |

## API Costs

LiveTitles uses a **bring-your-own-key** (BYOK) model. Approximate costs:

- **Transcription:** ~$0.007/min (Deepgram)
- **Translation:** ~$0.45–$0.56/hour (Claude, only when enabled)

## Releases

Releases are built automatically via GitHub Actions when a version tag is pushed:

```bash
git tag v0.1.0
git push origin v0.1.0
```

A signed and notarized `.dmg` is uploaded to the [GitHub Releases](https://github.com/ddanninger/livetitles/releases) page.

## License

MIT — see [LICENSE](LICENSE) for details.
