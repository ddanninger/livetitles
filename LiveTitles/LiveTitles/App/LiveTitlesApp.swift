import SwiftUI
import AppKit

@main
struct LiveTitlesApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(nsImage: menuBarIcon(recording: appState.isRecording))
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }

    private func menuBarIcon(recording: Bool) -> NSImage {
        let baseImage = NSImage(named: "MenuBarIcon")!
        let size = NSSize(width: 18, height: 18)

        let composed = NSImage(size: size, flipped: false) { rect in
            baseImage.draw(in: rect)

            if recording {
                let dotSize: CGFloat = 6
                let dotRect = NSRect(
                    x: rect.maxX - dotSize,
                    y: 0,
                    width: dotSize,
                    height: dotSize
                )
                NSColor.red.setFill()
                NSBezierPath(ovalIn: dotRect).fill()
            }

            return true
        }

        composed.isTemplate = !recording
        return composed
    }
}
