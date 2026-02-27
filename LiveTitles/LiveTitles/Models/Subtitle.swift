import SwiftUI

struct SubtitleLine: Identifiable, Equatable {
    let id: UUID
    let speaker: Speaker
    let text: String
    let translation: String?
    let timestamp: Double
    let isFinal: Bool
    let createdAt: Date

    init(id: UUID, speaker: Speaker, text: String, translation: String?, timestamp: Double, isFinal: Bool, createdAt: Date = Date()) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.translation = translation
        self.timestamp = timestamp
        self.isFinal = isFinal
        self.createdAt = createdAt
    }
}
