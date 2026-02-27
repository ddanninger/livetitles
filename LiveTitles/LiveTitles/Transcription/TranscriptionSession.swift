import Foundation

@MainActor
final class TranscriptionSession {
    private let provider: TranscriptionProvider
    /// Kept as a separate non-isolated reference for audio thread access
    private nonisolated let audioSender: TranscriptionProvider
    private weak var appState: AppState?
    private var isActive = false

    init(provider: TranscriptionProvider, appState: AppState) {
        self.provider = provider
        self.audioSender = provider
        self.appState = appState
        setupCallbacks()
    }

    func start() {
        isActive = true
        Task {
            do {
                try await provider.connect()
            } catch {
                print("Transcription connection failed: \(error)")
                appState?.stopRecording()
            }
        }
    }

    func stop() {
        isActive = false
        provider.disconnect()
    }

    /// Called from the audio thread — must be non-blocking and thread-safe
    nonisolated func sendAudio(_ data: Data) {
        audioSender.sendAudio(data)
    }

    private func setupCallbacks() {
        provider.onResult = { [weak self] result in
            Task { @MainActor [weak self] in
                self?.appState?.updateSubtitles(with: result)
            }
        }

        provider.onError = { error in
            print("Transcription error: \(error)")
        }

        provider.onConnectionStateChange = { [weak self] state in
            Task { @MainActor [weak self] in
                self?.appState?.updateConnectionState(state)
            }
        }
    }
}
