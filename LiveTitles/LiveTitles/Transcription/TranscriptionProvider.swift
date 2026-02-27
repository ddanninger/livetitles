import Foundation

/// Protocol for speech-to-text providers (Deepgram, AssemblyAI, etc.)
protocol TranscriptionProvider: AnyObject {
    var onResult: ((TranscriptionResult) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
    var onConnectionStateChange: ((ConnectionState) -> Void)? { get set }

    func connect() async throws
    func disconnect()
    func sendAudio(_ data: Data)
}

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting
}
