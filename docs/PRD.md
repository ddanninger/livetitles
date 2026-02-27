# LiveTitles - Product Requirements Document (PRD)

## Context

There is currently no elegant, movie-style live captioning solution for Mac that combines real-time speech-to-text, multi-speaker identification, live translation, and persistent speaker recognition into one polished desktop experience. Existing tools are either enterprise-grade (expensive, complex), browser-based (laggy, limited), or lack speaker diarization entirely. LiveTitles fills this gap as a native Mac app that feels like watching subtitles in a cinema — beautiful, real-time, and intelligent.

---

## 1. Product Vision

**One-liner:** LiveTitles turns any conversation into a beautifully captioned, translated, multi-speaker live transcript — like subtitles in a movie, right on your Mac.

**Target Users:**
- Multilingual teams in meetings or calls
- Content creators / streamers who want live captions
- Hearing-impaired users who need real-time transcription
- Journalists conducting interviews
- Students in lectures or seminars
- Anyone in a multi-language environment

---

## 2. Core User Stories

### 2.1 Live Captioning (Must Have - MVP)
> *"As a user, I want to see a live, movie-style caption overlay on my screen so that I can read what is being said in real-time."*

**Acceptance Criteria:**
- Captions appear as a floating overlay (always-on-top) on the Mac desktop
- Text appears word-by-word or phrase-by-phrase with smooth animation (cinema feel)
- Minimal latency between speech and displayed text (< 1 second perceived)
- User can position the caption bar anywhere on screen (drag & dock)
- Caption bar is semi-transparent and non-intrusive
- Works with system microphone input (meetings, in-person conversations)
- Works with system audio (capturing audio from apps like Zoom, Teams, etc.)

### 2.2 Multi-Speaker Detection (Must Have - MVP)
> *"As a user, I want to see who is speaking, distinguished by color or label, so I can follow a multi-person conversation."*

**Acceptance Criteria:**
- Each detected speaker gets a unique color assignment
- Speaker labels shown as "Speaker 1", "Speaker 2", etc. by default
- Colors are consistent within a session (same speaker = same color)
- Supports at least 4-6 concurrent speakers
- Visual distinction is clear and accessible (not only color-dependent — also includes labels/icons)

### 2.3 Live Translation (Must Have - MVP)
> *"As a user, I want to see a real-time translation of the spoken words into my chosen language alongside or below the original text."*

**Acceptance Criteria:**
- User selects one or more target translation languages from settings
- Translation appears in parallel (e.g., original on top, translation below)
- Translation updates in near real-time as sentences complete
- Supports at minimum: English, German, Spanish, French, Japanese, Chinese, Korean, Portuguese
- User can toggle translation on/off without stopping transcription

### 2.4 Speaker Identification & Persistence (Should Have - V1.1)
> *"As a user, I want the app to learn speaker names when they introduce themselves and remember them for future sessions."*

**Acceptance Criteria:**
- When a speaker says something like "Hi, I'm Sarah" or "My name is Tom", the app captures the name
- User gets a confirmation prompt: "Speaker 2 identified as 'Sarah' — Save?"
- Saved speakers are persisted locally across sessions
- On next session, if the same voice profile is detected, the saved name is auto-assigned
- User can manually rename, edit, or delete saved speaker profiles
- Speaker profile management screen accessible from settings

### 2.5 Transcript History & Export (Should Have - V1.1)
> *"As a user, I want to review past transcriptions and export them so I can use them for notes or records."*

**Acceptance Criteria:**
- All sessions are auto-saved locally with timestamp, duration, speaker info
- User can browse past sessions in a session history view
- Each session shows full transcript with speaker labels and timestamps
- Export formats: Plain text (.txt), Subtitle file (.srt), Markdown (.md), PDF
- Search across past transcriptions

---

## 3. User Experience & Design Principles

### 3.1 The "Cinema Subtitle" Experience
The app has **no main window**. The only visible UI while captioning is the subtitle text itself — floating directly over your desktop, exactly like movie subtitles. Nothing else. No window frame, no background app window, no dock icon during use.

- **Subtitle text** appears at the bottom of the screen by default (position configurable)
- **Font:** Clean, high-contrast, legible sans-serif (think Netflix/cinema subtitle style)
- **Animation:** Text fades in smoothly word-by-word or phrase-by-phrase, old lines fade out
- **Background:** Subtle semi-transparent dark shadow/bar behind text for readability on any desktop background
- **No window chrome:** No title bar, no close button, no borders — just the text floating on screen
- **Speaker colors:** Each speaker's text appears in their assigned color, with a small speaker label (e.g., "Maria:" or "Speaker 1:") preceding their words
- **Lines:** Shows last 1-2 lines of text, auto-scrolls as new speech comes in. Old text disappears like real subtitles.

### 3.2 Menu Bar — The Only Control Surface
The **menu bar icon** is the single place to control the app. There is no dock icon, no app window. Everything is accessed from the top menu bar:

| Menu Item | Description |
|-----------|-------------|
| **Start / Stop** | Toggle captioning on/off (primary action) |
| **Settings** | Opens a settings popover/window with all configuration |
| **Status indicator** | Red dot = recording, gray = idle |

### 3.3 Settings (accessible from menu bar)
| Setting | Description |
|---------|-------------|
| **Subtitle position** | Where on screen the subtitles appear (bottom-center default, configurable: top, middle, bottom; left, center, right) |
| **Font size** | Small / Medium / Large / Extra Large |
| **Opacity** | How transparent the subtitle background bar is |
| **Audio source** | Which microphone or audio input to use |
| **Speech language** | Primary language being spoken |
| **Translation language** | Target translation language (or off) |
| **Speaker colors** | View/edit speaker color assignments |
| **Transcript history** | Browse and export past sessions (V1.1) |
| **Speaker profiles** | Manage saved speaker identities (V1.1) |

### 3.4 Display Modes (future)
The MVP is **subtitle-only mode**. Additional modes come later:

| Mode | Version | Description |
|------|---------|-------------|
| **Subtitle Mode** (default) | MVP | Floating text on screen, no window, movie-style |
| **Panel Mode** | V1.2+ | Side panel with scrolling full transcript, speaker labels, timestamps |
| **Fullscreen Mode** | V1.2+ | Large centered captions for presentations/stage use |

---

## 4. Feature Prioritization (MoSCoW)

### Must Have (MVP)
- Live speech-to-text captioning as floating subtitle text (no window, no chrome — just text on screen)
- Menu bar icon as the only control surface (start/stop, settings, status)
- No dock icon, no app window — menu bar app only
- System microphone input capture
- Multi-speaker detection with color coding
- Real-time translation (at least 5 languages)
- Configurable subtitle position on screen (via settings)
- Settings: font size, opacity, audio source, speech language, translation language

### Should Have (V1.1)
- Speaker name identification from introductions
- Persistent speaker profiles across sessions
- Session history & transcript browsing
- Export (txt, srt, md)
- System audio capture (app audio from Zoom/Teams)
- Panel display mode
- Dark/light theme support

### Could Have (V1.2+)
- Fullscreen & minimal display modes
- Keyword highlighting / bookmarking in transcripts
- Custom speaker color assignment
- Hotkey to tag/bookmark moments during live session
- Multi-language simultaneous translation (e.g., show 2 translations at once)
- Confidence indicator for low-confidence transcriptions
- Integration with calendar apps to auto-name sessions

### Won't Have (Out of Scope for now)
- Cloud sync / multi-device sync
- Collaboration features (shared transcripts)
- Video recording / screen recording
- Mobile companion app
- Real-time editing of live captions

---

## 5. Key Metrics & Success Criteria

| Metric | Target |
|--------|--------|
| Transcription accuracy | > 90% for clear speech in supported languages |
| Perceived latency (speech to text on screen) | < 1 second |
| Translation latency | < 2 seconds after sentence completion |
| Speaker detection accuracy | > 85% correct speaker attribution |
| Speaker re-identification (returning sessions) | > 75% match rate |
| App cold start to "listening" | < 3 seconds |
| CPU usage while transcribing | < 15% on Apple Silicon |
| Session support | Continuous sessions up to 4 hours |

---

## 6. User Flows

### Flow 1: First Launch
1. User opens LiveTitles for the first time
2. Onboarding screen explains core features (3 slides max)
3. User grants microphone permission
4. User selects primary language (speech) and optional translation language
5. App opens in Subtitle Mode — ready to go
6. Menu bar icon appears

### Flow 2: Quick Start Captioning
1. User clicks menu bar icon → "Start Captioning"
2. Subtitle bar appears at bottom of screen
3. Speech is transcribed live with speaker colors
4. Translation (if enabled) appears below original text
5. User clicks menu bar → "Stop" to end session
6. Session auto-saved to history

### Flow 3: Speaker Introduces Themselves
1. During active captioning, Speaker 2 says: "Hey everyone, I'm Maria"
2. App detects name introduction pattern
3. Small toast notification: "Speaker 2 identified as **Maria** — [Save] [Dismiss]"
4. User clicks Save → Speaker 2 label changes to "Maria" with their assigned color
5. Maria's voice profile saved to local storage

### Flow 4: Returning Speaker Recognition
1. User starts a new session
2. A previously saved speaker (Maria) starts talking
3. App matches voice profile → auto-assigns "Maria" label and her previous color
4. Small toast: "Recognized: Maria" (dismisses after 3s)

---

## 7. Constraints & Assumptions

### Assumptions
- Users have a Mac running macOS 13 (Ventura) or later
- Users have a working microphone (built-in or external)
- Internet connection required (cloud-powered transcription & translation)
- Two equal use cases: video calls (Zoom/Teams) AND in-person conversations

### Constraints
- Must respect macOS privacy model (explicit permission for mic, audio capture)
- System audio capture requires macOS audio driver setup (may need user to install audio routing helper on macOS < 15; macOS 15+ has native audio capture APIs)
- Cloud APIs required — app needs internet connectivity for core functionality
- Must run efficiently on Apple Silicon (M1+); Intel support nice-to-have
- Open source — code must be clean, documented, and contributor-friendly

---

## 8. Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Business model** | Free / Open Source | Community-driven, no paywall. Potentially hosted on GitHub. |
| **Primary use case** | Both remote calls AND in-person | App must work equally well for Zoom/Teams calls and face-to-face conversations. |
| **Privacy / Processing** | Cloud-powered (best quality) | Prioritize transcription and translation accuracy using cloud APIs. Internet required. |
| **Distribution** | Direct download + open source repo | No App Store restrictions; users build from source or download releases. |

### Remaining Open Questions
1. **Localization:** Should the app UI itself be localized beyond English?
2. **Accessibility:** Should we target WCAG compliance for the app UI itself?
3. **Cloud provider:** Which STT / translation APIs to use? (Technical decision — deferred)

---

## 9. Release Plan

| Phase | Scope | Target |
|-------|-------|--------|
| **Alpha** | Core captioning + subtitle overlay + multi-speaker colors | Phase 1 |
| **MVP / Beta** | + Translation + menu bar + settings + audio source selection | Phase 2 |
| **V1.0 Public** | + Polish, onboarding, basic session history | Phase 3 |
| **V1.1** | + Speaker identification, persistence, export, system audio | Phase 4 |
| **V1.2** | + Additional display modes, bookmarks, advanced features | Phase 5 |

---

*This PRD is a Product Owner deliverable. Technical architecture, stack decisions, and implementation planning will follow as a separate document.*
