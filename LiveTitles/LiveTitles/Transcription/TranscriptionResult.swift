import Foundation

struct TranscriptionResult {
    let words: [TranscribedWord]
    let isFinal: Bool
    let channel: Int
    let detectedLanguage: String?

    var text: String {
        words.map(\.text).joined(separator: " ")
    }

    var speakerCount: Int {
        Set(words.map(\.speakerIndex)).count
    }
}

struct TranscribedWord: Identifiable {
    let id = UUID()
    let text: String
    let startTime: Double
    let endTime: Double
    let confidence: Double
    let speakerIndex: Int
    let isPunctuation: Bool

    init(text: String, startTime: Double, endTime: Double, confidence: Double, speakerIndex: Int) {
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
        self.speakerIndex = speakerIndex
        self.isPunctuation = text.rangeOfCharacter(from: .alphanumerics) == nil
    }
}
