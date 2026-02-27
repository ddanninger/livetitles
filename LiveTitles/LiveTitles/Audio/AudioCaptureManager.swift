import AVFoundation
import Foundation

final class AudioCaptureManager {
    private var audioEngine: AVAudioEngine?
    private var onAudioData: ((Data) -> Void)?
    private let processingQueue = DispatchQueue(label: "com.livetitles.audio", qos: .userInteractive)

    /// Target format for Deepgram: Linear PCM, 16-bit, 16kHz, mono
    private let targetSampleRate: Double = 16000
    private let targetChannels: AVAudioChannelCount = 1

    // Audio recording
    private var audioFile: AVAudioFile?
    private(set) var recordingURL: URL?

    func startCapture(recordToFile: URL? = nil, onAudioData: @escaping (Data) -> Void) throws {
        self.onAudioData = onAudioData

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Set up file recording if requested
        if let fileURL = recordToFile {
            let recordFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: inputFormat.sampleRate,
                channels: 1,
                interleaved: false
            )!
            audioFile = try AVAudioFile(forWriting: fileURL, settings: recordFormat.settings)
            recordingURL = fileURL
            print("[LiveTitles] Audio recording to \(fileURL.path)")
        }

        // Use the native input format for the tap, then convert on a separate queue
        let bufferSize: AVAudioFrameCount = 8192

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: targetSampleRate,
            channels: targetChannels,
            interleaved: true
        ) else {
            throw AudioCaptureError.formatNotSupported
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioCaptureError.converterCreationFailed
        }

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }

            // Write to file on processing queue
            if self.audioFile != nil {
                self.processingQueue.async {
                    self.writeToFile(buffer)
                }
            }

            // Move heavy conversion off the audio render thread
            self.processingQueue.async {
                self.processAudioBuffer(buffer, converter: converter, targetFormat: targetFormat)
            }
        }

        engine.prepare()
        try engine.start()
        audioEngine = engine
        print("[LiveTitles] Audio capture started (\(inputFormat.sampleRate)Hz → \(targetSampleRate)Hz)")
    }

    func stopCapture() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        onAudioData = nil
        audioFile = nil
        if let url = recordingURL {
            print("[LiveTitles] Audio recording saved to \(url.path)")
        }
    }

    private func writeToFile(_ buffer: AVAudioPCMBuffer) {
        guard let file = audioFile else { return }
        do {
            try file.write(from: buffer)
        } catch {
            if arc4random_uniform(100) == 0 {
                print("[LiveTitles] Audio file write error: \(error)")
            }
        }
    }

    private func processAudioBuffer(
        _ buffer: AVAudioPCMBuffer,
        converter: AVAudioConverter,
        targetFormat: AVAudioFormat
    ) {
        let ratio = targetSampleRate / buffer.format.sampleRate
        let frameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard frameCount > 0 else { return }

        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: frameCount
        ) else { return }

        var error: NSError?
        var isDone = false

        converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
            if isDone {
                outStatus.pointee = .noDataNow
                return nil
            }
            isDone = true
            outStatus.pointee = .haveData
            return buffer
        }

        if let error {
            // Only log occasionally to avoid spamming
            if arc4random_uniform(100) == 0 {
                print("[LiveTitles] Audio conversion error: \(error)")
            }
            return
        }

        guard convertedBuffer.frameLength > 0,
              let channelData = convertedBuffer.int16ChannelData else { return }

        let data = Data(
            bytes: channelData[0],
            count: Int(convertedBuffer.frameLength) * MemoryLayout<Int16>.size
        )
        onAudioData?(data)
    }
}

enum AudioCaptureError: LocalizedError {
    case formatNotSupported
    case converterCreationFailed
    case microphonePermissionDenied

    var errorDescription: String? {
        switch self {
        case .formatNotSupported:
            return "The target audio format is not supported"
        case .converterCreationFailed:
            return "Failed to create audio format converter"
        case .microphonePermissionDenied:
            return "Microphone access is required for captioning"
        }
    }
}
