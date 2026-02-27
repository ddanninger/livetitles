import SwiftUI

struct Speaker: Identifiable, Equatable, Hashable {
    let id: Int
    var name: String
    var color: Color

    var displayName: String {
        name.isEmpty ? "Speaker \(id + 1)" : name
    }

    static let defaultColors: [Color] = [
        .white,
        .cyan,
        .yellow,
        .green,
        .orange,
        .pink,
        .purple,
        .mint,
    ]

    static func defaultSpeaker(index: Int) -> Speaker {
        Speaker(
            id: index,
            name: "",
            color: defaultColors[index % defaultColors.count]
        )
    }
}
