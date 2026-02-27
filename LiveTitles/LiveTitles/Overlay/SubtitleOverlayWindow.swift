import AppKit
import SwiftUI

final class SubtitleOverlayWindow: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        level = .screenSaver
        isOpaque = false
        backgroundColor = .clear
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hasShadow = false
        isMovableByWindowBackground = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        self.contentView = contentView

        positionAtBottom()
    }

    private func positionAtBottom() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowWidth: CGFloat = 800
        let windowHeight: CGFloat = 500
        let bottomMargin: CGFloat = 80

        let x = screenFrame.midX - windowWidth / 2
        let y = screenFrame.minY + bottomMargin

        setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }

    func updatePosition(_ position: SubtitlePosition) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowSize = frame.size

        let x: CGFloat
        let y: CGFloat

        switch position.horizontal {
        case .left:
            x = screenFrame.minX + 40
        case .center:
            x = screenFrame.midX - windowSize.width / 2
        case .right:
            x = screenFrame.maxX - windowSize.width - 40
        }

        switch position.vertical {
        case .top:
            y = screenFrame.maxY - windowSize.height - 40
        case .middle:
            y = screenFrame.midY - windowSize.height / 2
        case .bottom:
            y = screenFrame.minY + 80
        }

        setFrameOrigin(NSPoint(x: x, y: y))
    }
}

struct SubtitlePosition {
    var horizontal: HorizontalPosition = .center
    var vertical: VerticalPosition = .bottom

    enum HorizontalPosition: String, CaseIterable {
        case left, center, right
    }

    enum VerticalPosition: String, CaseIterable {
        case top, middle, bottom
    }
}
