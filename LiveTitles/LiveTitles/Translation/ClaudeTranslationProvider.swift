import Foundation

final class ClaudeTranslationProvider: TranslationProvider {
    private let apiKey: String
    private let model: String

    init(apiKey: String, model: String = Constants.Anthropic.translationModel) {
        self.apiKey = apiKey
        self.model = model
    }

    func translate(
        text: String,
        from sourceLanguage: String,
        to targetLanguage: String
    ) async throws -> String {
        let body = buildRequestBody(text: text, from: sourceLanguage, to: targetLanguage, stream: false)
        let request = try buildRequest(body: body, stream: false)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw TranslationError.apiError(statusCode: statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let translatedText = firstBlock["text"] as? String else {
            throw TranslationError.invalidResponse
        }

        return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func translateStreaming(
        text: String,
        from sourceLanguage: String,
        to targetLanguage: String,
        onToken: @escaping (String) -> Void
    ) async throws {
        let body = buildRequestBody(text: text, from: sourceLanguage, to: targetLanguage, stream: true)
        let request = try buildRequest(body: body, stream: true)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw TranslationError.apiError(statusCode: statusCode)
        }

        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst(6))
            guard jsonString != "[DONE]",
                  let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            if let type = json["type"] as? String,
               type == "content_block_delta",
               let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                onToken(text)
            }
        }
    }

    // MARK: - Private

    private func buildRequest(body: [String: Any], stream: Bool) throws -> URLRequest {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw TranslationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func buildRequestBody(
        text: String,
        from sourceLanguage: String,
        to targetLanguage: String,
        stream: Bool
    ) -> [String: Any] {
        var body: [String: Any] = [
            "model": model,
            "max_tokens": 512,
            "system": """
                You are a real-time subtitle translator. Translate the following spoken text \
                from \(sourceLanguage) to \(targetLanguage). Output ONLY the translation, \
                nothing else. Preserve the tone and style of spoken language. \
                Keep it natural and conversational.
                """,
            "messages": [
                ["role": "user", "content": text]
            ],
        ]

        if stream {
            body["stream"] = true
        }

        return body
    }
}

enum TranslationError: LocalizedError {
    case invalidURL
    case apiError(statusCode: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .apiError(let code):
            return "API error (status \(code))"
        case .invalidResponse:
            return "Invalid response from translation API"
        }
    }
}
