import Foundation

/// Protocol for translation providers (Claude, GPT, Gemini, DeepL, etc.)
protocol TranslationProvider: AnyObject {
    func translate(
        text: String,
        from sourceLanguage: String,
        to targetLanguage: String
    ) async throws -> String

    func translateStreaming(
        text: String,
        from sourceLanguage: String,
        to targetLanguage: String,
        onToken: @escaping (String) -> Void
    ) async throws
}
