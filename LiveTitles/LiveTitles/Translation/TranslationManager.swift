import Foundation

/// Coordinates translation: takes final subtitle text, translates it, returns result by ID.
@MainActor
final class TranslationManager {
    private var provider: TranslationProvider?
    private let cache = TranslationCache()
    private var sourceLanguage: String = "en"
    private var targetLanguage: String = ""
    private var activeTasks: [UUID: Task<Void, Never>] = [:]

    /// Called when a translation is ready for a specific subtitle line
    var onTranslation: ((_ lineID: UUID, _ translation: String) -> Void)?

    var isConfigured: Bool {
        provider != nil && !targetLanguage.isEmpty
    }

    func configure(apiKey: String, sourceLanguage: String, targetLanguage: String) {
        guard !apiKey.isEmpty, !targetLanguage.isEmpty else {
            provider = nil
            return
        }

        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.provider = ClaudeTranslationProvider(apiKey: apiKey)
    }

    /// Translate a specific subtitle line's text
    func translate(lineID: UUID, text: String) {
        guard isConfigured, !text.isEmpty else { return }

        // Cancel any existing task for this line (e.g. if text was updated)
        activeTasks[lineID]?.cancel()

        activeTasks[lineID] = Task { [weak self] in
            guard let self else { return }
            await self.performTranslation(lineID: lineID, text: text)
            self.activeTasks.removeValue(forKey: lineID)
        }
    }

    func stop() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
    }

    private func performTranslation(lineID: UUID, text: String) async {
        // Check cache first
        if let cached = cache.get(text: text, targetLanguage: targetLanguage) {
            onTranslation?(lineID, cached)
            return
        }

        guard let provider else { return }

        do {
            let translation = try await provider.translate(
                text: text,
                from: sourceLanguage,
                to: targetLanguage
            )

            guard !Task.isCancelled else { return }

            cache.set(text: text, targetLanguage: targetLanguage, translation: translation)
            onTranslation?(lineID, translation)
        } catch {
            print("Translation failed for line \(lineID): \(error)")
        }
    }
}
