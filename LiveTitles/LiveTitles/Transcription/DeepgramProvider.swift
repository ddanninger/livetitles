import Foundation

final class DeepgramProvider: TranscriptionProvider {
    var onResult: ((TranscriptionResult) -> Void)?
    var onError: ((Error) -> Void)?
    var onConnectionStateChange: ((ConnectionState) -> Void)?

    private let apiKey: String
    private let language: String
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var isConnected = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var keepAliveTimer: Timer?

    init(apiKey: String, language: String = "multi") {
        self.apiKey = apiKey
        self.language = language
    }

    func connect() async throws {
        onConnectionStateChange?(.connecting)

        let urlString = [
            "wss://api.deepgram.com/v1/listen?",
            "model=nova-3",
            "&language=\(language)",
            "&interim_results=true",
            "&punctuate=true",
            "&smart_format=true",
            "&encoding=linear16",
            "&sample_rate=16000",
            "&channels=1",
        ].joined()

        guard let url = URL(string: urlString) else {
            throw DeepgramError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: request)
        task.resume()

        webSocketTask = task
        urlSession = session
        isConnected = true
        reconnectAttempts = 0

        onConnectionStateChange?(.connected)
        startReceiving()
        startKeepAlive()
    }

    func disconnect() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession = nil
        isConnected = false
        onConnectionStateChange?(.disconnected)
    }

    func sendAudio(_ data: Data) {
        guard isConnected, let task = webSocketTask else { return }
        task.send(.data(data)) { [weak self] error in
            if let error {
                self?.handleError(error)
            }
        }
    }

    // MARK: - Private

    private func startReceiving() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.startReceiving()
            case .failure(let error):
                self.handleError(error)
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseResponse(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseResponse(text)
            }
        @unknown default:
            break
        }
    }

    private func parseResponse(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        // Check if this is a transcription result
        guard let channel = json["channel"] as? [String: Any],
              let alternatives = channel["alternatives"] as? [[String: Any]],
              let firstAlt = alternatives.first,
              let wordsArray = firstAlt["words"] as? [[String: Any]] else {
            return
        }

        let isFinal = json["is_final"] as? Bool ?? false
        let channelIndex = (json["channel_index"] as? [Int])?.first ?? 0
        let detectedLanguage = channel["detected_language"] as? String
            ?? firstAlt["detected_language"] as? String

        let words = wordsArray.compactMap { wordDict -> TranscribedWord? in
            guard let word = wordDict["word"] as? String,
                  let start = wordDict["start"] as? Double,
                  let end = wordDict["end"] as? Double else {
                return nil
            }

            let confidence = wordDict["confidence"] as? Double ?? 0
            let speaker = wordDict["speaker"] as? Int ?? 0

            return TranscribedWord(
                text: word,
                startTime: start,
                endTime: end,
                confidence: confidence,
                speakerIndex: speaker
            )
        }

        guard !words.isEmpty else { return }

        let result = TranscriptionResult(
            words: words,
            isFinal: isFinal,
            channel: channelIndex,
            detectedLanguage: detectedLanguage
        )

        DispatchQueue.main.async { [weak self] in
            self?.onResult?(result)
        }
    }

    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.onError?(error)
        }

        if isConnected {
            attemptReconnect()
        }
    }

    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            onConnectionStateChange?(.disconnected)
            return
        }

        isConnected = false
        onConnectionStateChange?(.reconnecting)
        reconnectAttempts += 1

        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            Task {
                try? await self?.connect()
            }
        }
    }

    private func startKeepAlive() {
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if let error {
                    self?.handleError(error)
                }
            }
        }
    }
}

enum DeepgramError: LocalizedError {
    case invalidURL
    case connectionFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Deepgram API URL"
        case .connectionFailed: return "Failed to connect to Deepgram"
        case .invalidResponse: return "Invalid response from Deepgram"
        }
    }
}
