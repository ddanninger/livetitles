import SwiftUI

@MainActor
final class SpeakerManager {
    static let shared = SpeakerManager()

    private var speakers: [Int: Speaker] = [:]

    func speaker(for index: Int) -> Speaker {
        if let existing = speakers[index] {
            return existing
        }
        let newSpeaker = Speaker.defaultSpeaker(index: index)
        speakers[index] = newSpeaker
        return newSpeaker
    }

    func updateName(for index: Int, name: String) {
        speakers[index]?.name = name
    }

    func reset() {
        speakers.removeAll()
    }
}
