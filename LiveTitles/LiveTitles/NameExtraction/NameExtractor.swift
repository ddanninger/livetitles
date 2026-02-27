import Foundation

/// Extracts speaker names from transcribed text.
/// Uses regex patterns first (free, instant), falls back to Claude for ambiguous cases.
final class NameExtractor {
    private var anthropicAPIKey: String?

    func configure(anthropicAPIKey: String) {
        self.anthropicAPIKey = anthropicAPIKey.isEmpty ? nil : anthropicAPIKey
    }

    func extractName(from text: String) -> String? {
        // Try regex patterns first (handles ~80% of cases)
        if let name = extractNameWithRegex(text) {
            return name
        }
        return nil
    }

    /// Async version that falls back to Claude for ambiguous cases
    func extractNameAsync(from text: String) async -> String? {
        // Try regex first
        if let name = extractNameWithRegex(text) {
            return name
        }

        // Fall back to Claude if configured
        guard let apiKey = anthropicAPIKey else { return nil }
        return await extractNameWithClaude(text: text, apiKey: apiKey)
    }

    // MARK: - Regex Extraction

    private func extractNameWithRegex(_ text: String) -> String? {
        let patterns = [
            // "I'm Sarah" / "I am Sarah"
            #"(?:I'?m|I am)\s+([A-Z][a-zA-Z]+)"#,
            // "My name is Sarah"
            #"[Mm]y name(?:'s| is)\s+([A-Z][a-zA-Z]+)"#,
            // "Call me Sarah"
            #"[Cc]all me\s+([A-Z][a-zA-Z]+)"#,
            // "This is Sarah" / "Hey this is Sarah"
            #"(?:[Tt]his is|[Hh]ey,?\s+this is)\s+([A-Z][a-zA-Z]+)"#,
            // "Hi, Sarah here" / "Sarah here"
            #"(?:[Hh]i,?\s+)?([A-Z][a-zA-Z]+)\s+here\b"#,
            // "It's Sarah" / "Hey it's Sarah"
            #"(?:[Hh]ey,?\s+)?[Ii]t'?s\s+([A-Z][a-zA-Z]+)"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let nameRange = Range(match.range(at: 1), in: text) {
                let name = String(text[nameRange])
                if !isCommonWord(name) {
                    return name
                }
            }
        }

        return nil
    }

    // MARK: - Claude Fallback

    private func extractNameWithClaude(text: String, apiKey: String) async -> String? {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": Constants.Anthropic.haikuModel,
            "max_tokens": 50,
            "system": """
                Extract the speaker's name from the transcribed text if they are introducing themselves. \
                Reply with ONLY the name, or "NONE" if no name introduction is found. \
                Examples: "Hi everyone I'm Sarah" → "Sarah", "Let me share my screen" → "NONE"
                """,
            "messages": [["role": "user", "content": text]],
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let firstBlock = content.first,
                  let result = firstBlock["text"] as? String else {
                return nil
            }

            let name = result.trimmingCharacters(in: .whitespacesAndNewlines)
            return name == "NONE" || name.isEmpty ? nil : name
        } catch {
            return nil
        }
    }

    private func isCommonWord(_ word: String) -> Bool {
        let commonWords: Set<String> = [
            "The", "This", "That", "Here", "There", "Just",
            "Now", "Well", "Sure", "Good", "Great", "Fine",
            "Actually", "Really", "Sorry", "Thanks", "Please",
        ]
        return commonWords.contains(word)
    }
}
