import AppKit
import SwiftUI
import Combine

@MainActor
final class SubtitleOverlayManager: ObservableObject {
    private var overlayWindow: SubtitleOverlayWindow?
    private var cancellables = Set<AnyCancellable>()

    func showOverlay(appState: AppState) {
        guard overlayWindow == nil else { return }

        let subtitleView = SubtitleView()
            .environmentObject(appState)

        let hostingView = NSHostingView(rootView: subtitleView)
        hostingView.autoresizingMask = [.width, .height]

        let window = SubtitleOverlayWindow(contentView: hostingView)
        window.orderFront(nil)
        overlayWindow = window
    }

    func hideOverlay() {
        overlayWindow?.close()
        overlayWindow = nil
    }

    func updatePosition(_ position: SubtitlePosition) {
        overlayWindow?.updatePosition(position)
    }
}
