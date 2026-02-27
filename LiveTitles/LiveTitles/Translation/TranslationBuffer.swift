import Foundation

/// Buffers transcribed text into sentence-sized chunks before sending to translation.
/// Accumulates final transcription text and flushes when a sentence boundary is detected
/// or after a silence timeout.
final class TranslationBuffer {
    private var buffer = ""
    private var flushTimer: Timer?
    private let silenceThreshold: TimeInterval = 2.0

    var onSentenceReady: ((String) -> Void)?

    /// Add finalized transcription text. Flushes on sentence endings or after silence.
    func addWord(_ text: String, isFinal: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !buffer.isEmpty {
            buffer += " "
        }
        buffer += trimmed

        // Flush immediately on sentence-ending punctuation
        if isFinal && hasSentenceEnding(buffer) {
            flush()
            return
        }

        // Set a timer to flush after silence gap
        flushTimer?.invalidate()
        flushTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            self?.flush()
        }
    }

    func flush() {
        flushTimer?.invalidate()
        flushTimer = nil

        let text = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        buffer = ""
        onSentenceReady?(text)
    }

    func reset() {
        buffer = ""
        flushTimer?.invalidate()
        flushTimer = nil
    }

    private func hasSentenceEnding(_ text: String) -> Bool {
        let endings: [Character] = [".", "!", "?", "。", "！", "？"]
        guard let lastChar = text.last else { return false }
        return endings.contains(lastChar)
    }
}
