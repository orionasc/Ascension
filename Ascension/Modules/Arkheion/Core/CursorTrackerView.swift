#if os(macOS)
import SwiftUI
import AppKit

/// View that tracks the mouse location and hover state within its bounds
/// without interfering with hit testing. Used to drive the custom cursor
/// overlay.
struct CursorTrackerView: NSViewRepresentable {
    @Binding var location: CGPoint
    @Binding var hovering: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(location: $location, hovering: $hovering)
    }

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: TrackingView, context: Context) {}

    // MARK: - Coordinator
    class Coordinator {
        var location: Binding<CGPoint>
        var hovering: Binding<Bool>
        init(location: Binding<CGPoint>, hovering: Binding<Bool>) {
            self.location = location
            self.hovering = hovering
        }

        func update(location: CGPoint) {
            self.location.wrappedValue = location
        }

        func update(hovering: Bool) {
            self.hovering.wrappedValue = hovering
        }
    }

    // MARK: - Tracking View
    class TrackingView: NSView {
        weak var coordinator: Coordinator?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.acceptsMouseMovedEvents = true
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            for area in trackingAreas { removeTrackingArea(area) }
            let options: NSTrackingArea.Options = [
                .mouseMoved,
                .mouseEnteredAndExited,
                .activeInKeyWindow,
                .inVisibleRect
            ]
            let area = NSTrackingArea(rect: .zero, options: options, owner: self, userInfo: nil)
            addTrackingArea(area)
        }

        override func mouseMoved(with event: NSEvent) {
            coordinator?.update(location: convert(event.locationInWindow, from: nil))
        }

        override func mouseEntered(with event: NSEvent) {
            coordinator?.update(hovering: true)
        }

        override func mouseExited(with event: NSEvent) {
            coordinator?.update(hovering: false)
        }
    }
}
#endif
