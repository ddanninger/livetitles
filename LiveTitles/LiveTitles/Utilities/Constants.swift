import Foundation

enum Constants {
    enum Audio {
        static let sampleRate: Double = 16000
        static let channels: Int = 1
        static let bitDepth: Int = 16
    }

    enum Deepgram {
        static let baseURL = "wss://api.deepgram.com/v1/listen"
        static let model = "nova-3"
        static let keepAliveInterval: TimeInterval = 10
        static let maxReconnectAttempts = 5
    }

    enum Anthropic {
        static let baseURL = "https://api.anthropic.com/v1/messages"
        static let apiVersion = "2023-06-01"
        static let translationModel = "claude-sonnet-4-6"
        static let haikuModel = "claude-haiku-4-5"
    }

    enum Subtitle {
        static let maxVisibleLines = 2
        static let defaultFontSize: CGFloat = 16
        static let defaultOpacity: Double = 0.7
        static let fadeAnimationDuration: Double = 0.2
    }

    enum App {
        static let bundleIdentifier = "com.livetitles.app"
    }
}
