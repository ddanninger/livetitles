import Foundation

/// Coordinates translation: takes final subtitle text, translates it, returns result by ID.
@MainActor
final class TranslationManager {
    private var provider: TranslationProvider?
    private let cache = TranslationCache()
    private var sourceLanguage: String = "en"
    private var targetLanguage: String = ""
    private var tone: String = "casual"
    private var activeTasks: [UUID: Task<Void, Never>] = [:]

    /// Called when a translation is ready for a specific subtitle line
    var onTranslation: ((_ lineID: UUID, _ translation: String) -> Void)?

    var isConfigured: Bool {
        provider != nil && !targetLanguage.isEmpty
    }

    func configure(apiKey: String, sourceLanguage: String, targetLanguage: String, tone: String = "casual") {
        guard !apiKey.isEmpty, !targetLanguage.isEmpty else {
            provider = nil
            return
        }

        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.tone = tone
        self.provider = ClaudeTranslationProvider(apiKey: apiKey)
    }

    /// Translate a specific subtitle line's text.
    /// When detectedLanguage is provided, translates bidirectionally:
    /// if detected matches source → translate to target; if detected matches target → translate to source.
    func translate(lineID: UUID, text: String, detectedLanguage: String? = nil) {
        guard isConfigured, !text.isEmpty else { return }

        // Determine translation direction
        let (from, to) = resolveDirection(detectedLanguage: detectedLanguage)

        // Don't translate if detected language matches the target (already in the right language)
        // This shouldn't happen with proper direction resolution, but guard anyway
        guard from != to else { return }

        // Cancel any existing task for this line (e.g. if text was updated)
        activeTasks[lineID]?.cancel()

        activeTasks[lineID] = Task { [weak self] in
            guard let self else { return }
            await self.performTranslation(lineID: lineID, text: text, from: from, to: to)
            self.activeTasks.removeValue(forKey: lineID)
        }
    }

    /// Resolves which direction to translate based on detected language.
    private func resolveDirection(detectedLanguage: String?) -> (from: String, to: String) {
        guard let detected = detectedLanguage else {
            print("[LiveTitles] No detected language, using default: \(sourceLanguage) → \(targetLanguage)")
            return (sourceLanguage, targetLanguage)
        }

        // Normalize: "en-US" → "en"
        let detectedBase = String(detected.prefix(2))
        let targetBase = String(targetLanguage.prefix(2))

        if detectedBase == targetBase {
            // Speaking the translation language → translate back to source
            print("[LiveTitles] Detected \(detected) matches target (\(targetLanguage)), flipping: \(targetLanguage) → \(sourceLanguage)")
            return (targetLanguage, sourceLanguage)
        }
        // Default: speaking source language → translate to target
        print("[LiveTitles] Detected \(detected), translating: \(sourceLanguage) → \(targetLanguage)")
        return (sourceLanguage, targetLanguage)
    }

    func stop() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
    }

    private func performTranslation(lineID: UUID, text: String, from: String, to: String) async {
        // Check cache first
        if let cached = cache.get(text: text, targetLanguage: to) {
            onTranslation?(lineID, cached)
            return
        }

        guard let provider else { return }

        do {
            let translation = try await provider.translate(
                text: text,
                from: from,
                to: to,
                tone: tone
            )

            guard !Task.isCancelled else { return }

            cache.set(text: text, targetLanguage: to, translation: translation)
            onTranslation?(lineID, translation)
        } catch {
            print("Translation failed for line \(lineID): \(error)")
        }
    }
}
