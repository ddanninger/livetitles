import SwiftUI

struct SubtitleView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("subtitleFontSize") private var fontSize = 16.0
    @AppStorage("subtitleOpacity") private var backgroundOpacity = 0.7
    @AppStorage("subtitleVisibleBubbles") private var visibleBubbles = 3

    var body: some View {
        VStack(spacing: 4) {
            Spacer()

            ForEach(appState.subtitleLines.suffix(max(2, visibleBubbles))) { line in
                SubtitleLineView(
                    line: line,
                    fontSize: fontSize,
                    backgroundOpacity: backgroundOpacity
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity
                ))
            }
        }
        .frame(width: 780, height: 500, alignment: .bottom)
        .animation(.easeInOut(duration: 0.25), value: appState.subtitleLines.map(\.id))
    }
}

struct SubtitleLineView: View {
    let line: SubtitleLine
    var fontSize: Double = 16.0
    var backgroundOpacity: Double = 0.7

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(line.speaker.displayName + ":")
                .font(.system(size: fontSize, weight: .bold, design: .default))
                .foregroundColor(line.speaker.color)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 2) {
                Text(line.text)
                    .font(.system(size: fontSize, weight: .medium, design: .default))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if let translation = line.translation {
                    Text(translation)
                        .font(.system(size: fontSize - 2, weight: .regular, design: .default))
                        .foregroundColor(.white.opacity(0.75))
                        .italic()
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(backgroundOpacity))
        )
        .opacity(line.isFinal ? 1.0 : 0.65)
    }
}
