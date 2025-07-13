import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Overlay that renders a custom cursor while tracking the mouse location.
/// The system cursor is hidden when hovering over the parent view.
struct CursorOverlay: View {
    @Binding var location: CGPoint?

    var body: some View {
        ZStack(alignment: .topLeading) {
#if os(macOS)
            MouseTrackingView(location: $location)
#endif
            if let point = location {
                CustomCursorView(position: point)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

#if os(macOS)
/// SwiftUI wrapper providing continuous mouse location updates.
private struct MouseTrackingView: NSViewRepresentable {
    @Binding var location: CGPoint?

    func makeCoordinator() -> Coordinator { Coordinator(location: $location) }

    func makeNSView(context: Context) -> TrackingNSView {
        let view = TrackingNSView()
        view.onMove = { context.coordinator.updateLocation($0) }
        view.onHoverChanged = { context.coordinator.hoverChanged($0) }
        return view
    }

    func updateNSView(_ nsView: TrackingNSView, context: Context) {}

    static func dismantleNSView(_ nsView: TrackingNSView, coordinator: Coordinator) {
        coordinator.cleanup()
    }

    class Coordinator {
        @Binding var location: CGPoint?
        private var hovering = false
        init(location: Binding<CGPoint?>) { self._location = location }

        func updateLocation(_ point: CGPoint) {
            location = point
        }

        func hoverChanged(_ hovering: Bool) {
            guard self.hovering != hovering else { return }
            self.hovering = hovering
            if hovering {
                NSCursor.hide()
            } else {
                NSCursor.unhide()
                location = nil
            }
        }

        func cleanup() {
            if hovering { NSCursor.unhide() }
        }
    }

    class TrackingNSView: NSView {
        var onMove: ((CGPoint) -> Void)?
        var onHoverChanged: ((Bool) -> Void)?

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            for area in trackingAreas { removeTrackingArea(area) }
            let options: NSTrackingArea.Options = [
                .mouseEnteredAndExited,
                .mouseMoved,
                .activeInKeyWindow,
                .inVisibleRect,
                .enabledDuringMouseDrag
            ]
            addTrackingArea(NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil))
        }

        override func mouseEntered(with event: NSEvent) {
            onHoverChanged?(true)
        }

        override func mouseExited(with event: NSEvent) {
            onHoverChanged?(false)
        }

        override func mouseMoved(with event: NSEvent) {
            onMove?(convert(event.locationInWindow, from: nil))
        }

        override func mouseDragged(with event: NSEvent) {
            onMove?(convert(event.locationInWindow, from: nil))
        }
    }
}
#endif

/// Simple glowing dot used as the custom cursor.
private struct CustomCursorView: View {
    var position: CGPoint
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 10, height: 10)
            .shadow(color: Color.white.opacity(0.8), radius: 6)
            .position(position)
    }
}

