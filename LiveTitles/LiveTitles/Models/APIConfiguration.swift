import Foundation

struct APIConfiguration {
    var deepgramAPIKey: String
    var anthropicAPIKey: String
    var picovoiceAccessKey: String

    var speechLanguage: String
    var translationLanguage: String?

    var isDeepgramConfigured: Bool { !deepgramAPIKey.isEmpty }
    var isAnthropicConfigured: Bool { !anthropicAPIKey.isEmpty }
    var isTranslationAvailable: Bool { isAnthropicConfigured && translationLanguage != nil }

    static let empty = APIConfiguration(
        deepgramAPIKey: "",
        anthropicAPIKey: "",
        picovoiceAccessKey: "",
        speechLanguage: "en",
        translationLanguage: nil
    )
}
