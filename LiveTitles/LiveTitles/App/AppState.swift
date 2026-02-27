import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    // MARK: - Recording State
    @Published var isRecording = false
    @Published var connectionState: ConnectionState = .disconnected

    // MARK: - Subtitles
    @Published var subtitleLines: [SubtitleLine] = []
    @Published var isTranslationEnabled = true

    // MARK: - Configuration
    @Published var hasValidAPIKeys = false
    @Published var showingAPIKeySetup = false

    // MARK: - Transcript History
    private var transcriptLines: [SubtitleLine] = []
    private var recordingStartTime: Date?

    // MARK: - Managers
    let overlayManager = SubtitleOverlayManager()
    private var audioCaptureManager: AudioCaptureManager?
    private var transcriptionSession: TranscriptionSession?
    private let translationManager = TranslationManager()
    private var cancellables = Set<AnyCancellable>()
    private var fadeOutTimer: Timer?

    init() {
        checkAPIKeys()
        setupTranslationCallback()
    }

    // MARK: - Actions

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        guard hasValidAPIKeys else {
            showingAPIKeySetup = true
            return
        }

        let deepgramKey = SettingsManager.shared.deepgramAPIKey
        guard !deepgramKey.isEmpty else {
            showingAPIKeySetup = true
            return
        }

        // Reset speakers and transcript for new session
        SpeakerManager.shared.reset()
        subtitleLines = []
        transcriptLines = []
        recordingStartTime = Date()

        let anthropicKey = SettingsManager.shared.anthropicAPIKey

        let speechLang = UserDefaults.standard.string(forKey: "speechLanguage") ?? "multi"
        let translationLang = UserDefaults.standard.string(forKey: "translationLanguage") ?? ""

        let tone = UserDefaults.standard.string(forKey: "translationTone") ?? "casual"

        // Always configure translation if keys + language exist — toggle controls display
        if !anthropicKey.isEmpty && !translationLang.isEmpty {
            translationManager.configure(
                apiKey: anthropicKey,
                sourceLanguage: speechLang,
                targetLanguage: translationLang,
                tone: tone
            )
            print("[LiveTitles] Translation configured: \(speechLang) → \(translationLang)")
        } else {
            print("[LiveTitles] Translation not configured (missing key or target language)")
        }

        // Set up audio capture
        audioCaptureManager = AudioCaptureManager()

        // Determine audio recording file if enabled
        var audioRecordingURL: URL?
        if UserDefaults.standard.bool(forKey: "saveAudioRecording") {
            let dir = saveDirectoryURL()
            let fileFormatter = DateFormatter()
            fileFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
            let filename = "LiveTitles_\(fileFormatter.string(from: recordingStartTime ?? Date())).caf"
            audioRecordingURL = dir.appendingPathComponent(filename)
        }

        // Use restricted language detection when simultaneous translation is enabled
        let simultaneousTranslation = UserDefaults.standard.bool(forKey: "simultaneousTranslation")
        let provider: DeepgramProvider
        if simultaneousTranslation && speechLang != "multi" && !translationLang.isEmpty {
            provider = DeepgramProvider(
                apiKey: deepgramKey,
                detectLanguages: [speechLang, translationLang]
            )
        } else {
            provider = DeepgramProvider(apiKey: deepgramKey, language: speechLang)
        }
        transcriptionSession = TranscriptionSession(
            provider: provider,
            appState: self
        )

        do {
            try audioCaptureManager?.startCapture(recordToFile: audioRecordingURL) { [weak self] audioData in
                self?.transcriptionSession?.sendAudio(audioData)
            }
            transcriptionSession?.start()
            isRecording = true
            startFadeOutTimer()

            // Show the subtitle overlay
            overlayManager.showOverlay(appState: self)
        } catch {
            print("[LiveTitles] Failed to start audio capture: \(error)")
            audioCaptureManager = nil
            transcriptionSession = nil
        }
    }

    func stopRecording() {
        audioCaptureManager?.stopCapture()
        transcriptionSession?.stop()
        translationManager.stop()
        stopFadeOutTimer()

        // Save transcript if enabled
        if UserDefaults.standard.bool(forKey: "saveTranscript") && !transcriptLines.isEmpty {
            saveTranscript()
        }

        audioCaptureManager = nil
        transcriptionSession = nil
        isRecording = false
        connectionState = .disconnected

        // Hide overlay after a brief delay so last subtitle is visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.overlayManager.hideOverlay()
            self?.subtitleLines = []
        }
    }

    // MARK: - Subtitle Updates

    func updateSubtitles(with result: TranscriptionResult) {
        let lines = result.words
            .grouped(by: \.speakerIndex)
            .map { speakerIndex, words in
                let speaker = SpeakerManager.shared.speaker(for: speakerIndex)
                let text = words.map(\.text).joined(separator: " ")
                return SubtitleLine(
                    id: UUID(),
                    speaker: speaker,
                    text: text,
                    translation: nil,
                    timestamp: words.first?.startTime ?? 0,
                    isFinal: result.isFinal
                )
            }

        let maxBubbles = max(2, UserDefaults.standard.integer(forKey: "subtitleVisibleBubbles"))
        let keepCount = maxBubbles > 0 ? maxBubbles : 3

        if result.isFinal {
            // Append final lines, keeping only recent ones
            subtitleLines = (subtitleLines.filter(\.isFinal) + lines).suffix(keepCount * 2).map { $0 }

            // Accumulate for transcript save
            transcriptLines.append(contentsOf: lines)

            // Translate each final line if translation is enabled
            if isTranslationEnabled && translationManager.isConfigured {
                for line in lines {
                    translationManager.translate(
                        lineID: line.id,
                        text: line.text,
                        detectedLanguage: result.detectedLanguage
                    )
                }
            }
        } else {
            // Replace interim results (keep finals + show current interims)
            let finals = subtitleLines.filter(\.isFinal)
            subtitleLines = (finals + lines).suffix(keepCount * 2).map { $0 }
        }
    }

    func updateConnectionState(_ state: ConnectionState) {
        connectionState = state
    }

    // MARK: - Private

    private func saveDirectoryURL() -> URL {
        let customPath = UserDefaults.standard.string(forKey: "saveLocationPath") ?? ""
        if !customPath.isEmpty {
            // Try to resolve security-scoped bookmark
            if let bookmarkData = UserDefaults.standard.data(forKey: "saveLocationBookmark") {
                var isStale = false
                if let url = try? URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                ) {
                    _ = url.startAccessingSecurityScopedResource()
                    return url
                }
            }
            return URL(fileURLWithPath: customPath)
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func saveTranscript() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let startStr = dateFormatter.string(from: recordingStartTime ?? Date())
        let endStr = dateFormatter.string(from: Date())

        var md = "# LiveTitles Transcript\n\n"
        md += "**Date:** \(startStr) — \(endStr)\n\n"
        md += "---\n\n"

        for line in transcriptLines {
            md += "**\(line.speaker.displayName):** \(line.text)\n"
            if let translation = line.translation {
                md += "*\(translation)*\n"
            }
            md += "\n"
        }

        let fileFormatter = DateFormatter()
        fileFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "LiveTitles_\(fileFormatter.string(from: recordingStartTime ?? Date())).md"

        let dir = saveDirectoryURL()
        let fileURL = dir.appendingPathComponent(filename)

        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try md.write(to: fileURL, atomically: true, encoding: .utf8)
            print("[LiveTitles] Transcript saved to \(fileURL.path)")
        } catch {
            print("[LiveTitles] Failed to save transcript: \(error)")
        }
    }

    private func checkAPIKeys() {
        hasValidAPIKeys = !SettingsManager.shared.deepgramAPIKey.isEmpty
    }

    private func startFadeOutTimer() {
        fadeOutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.removeExpiredLines()
            }
        }
    }

    private func stopFadeOutTimer() {
        fadeOutTimer?.invalidate()
        fadeOutTimer = nil
    }

    private func removeExpiredLines() {
        let fadeOutSeconds = UserDefaults.standard.double(forKey: "subtitleFadeOutTime")
        let duration = fadeOutSeconds > 0 ? fadeOutSeconds : 8.0
        let cutoff = Date().addingTimeInterval(-duration)
        let before = subtitleLines.count
        subtitleLines.removeAll { $0.isFinal && $0.createdAt < cutoff }
        if subtitleLines.count != before {
            print("[LiveTitles] Faded out \(before - subtitleLines.count) expired subtitle(s)")
        }
    }

    private func setupTranslationCallback() {
        translationManager.onTranslation = { [weak self] lineID, translation in
            guard let self else { return }
            // Find the subtitle line by ID and add the translation
            if let index = self.subtitleLines.firstIndex(where: { $0.id == lineID }) {
                let existing = self.subtitleLines[index]
                self.subtitleLines[index] = SubtitleLine(
                    id: existing.id,
                    speaker: existing.speaker,
                    text: existing.text,
                    translation: translation,
                    timestamp: existing.timestamp,
                    isFinal: existing.isFinal
                )
                print("[LiveTitles] Translation added: \(existing.text) → \(translation)")
            }
            // Also update transcript history
            if let index = self.transcriptLines.firstIndex(where: { $0.id == lineID }) {
                let existing = self.transcriptLines[index]
                self.transcriptLines[index] = SubtitleLine(
                    id: existing.id,
                    speaker: existing.speaker,
                    text: existing.text,
                    translation: translation,
                    timestamp: existing.timestamp,
                    isFinal: existing.isFinal,
                    createdAt: existing.createdAt
                )
            }
        }
    }
}

// MARK: - Array Grouping Helper

extension Array {
    func grouped<Key: Hashable>(by keyPath: KeyPath<Element, Key>) -> [(Key, [Element])] {
        var groups: [Key: [Element]] = [:]
        var order: [Key] = []
        for element in self {
            let key = element[keyPath: keyPath]
            if groups[key] == nil {
                order.append(key)
            }
            groups[key, default: []].append(element)
        }
        return order.map { ($0, groups[$0]!) }
    }
}
