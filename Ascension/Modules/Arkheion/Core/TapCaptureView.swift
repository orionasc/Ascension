import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Captures single and double tap locations within its bounds.
struct TapCaptureView: View {
    var onTap: (CGPoint) -> Void
    var onDoubleTap: (CGPoint) -> Void
    var onLongPress: ((CGPoint) -> Void)? = nil

    var body: some View {
#if os(iOS)
        Representable(onTap: onTap, onDoubleTap: onDoubleTap, onLongPress: onLongPress)
#elseif os(macOS)
        Representable(onTap: onTap, onDoubleTap: onDoubleTap, onLongPress: onLongPress)
#else
        Color.clear
#endif
    }
}

#if os(iOS)
private struct Representable: UIViewRepresentable {
    var onTap: (CGPoint) -> Void
    var onDoubleTap: (CGPoint) -> Void
    var onLongPress: ((CGPoint) -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap, onDoubleTap: onDoubleTap, onLongPress: onLongPress) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let single = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        let double = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        let long = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        double.numberOfTapsRequired = 2
        single.require(toFail: double)
        view.addGestureRecognizer(single)
        view.addGestureRecognizer(double)
        view.addGestureRecognizer(long)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    class Coordinator: NSObject {
        var onTap: (CGPoint) -> Void
        var onDoubleTap: (CGPoint) -> Void
        var onLongPress: ((CGPoint) -> Void)?
        init(onTap: @escaping (CGPoint) -> Void, onDoubleTap: @escaping (CGPoint) -> Void, onLongPress: ((CGPoint) -> Void)?) {
            self.onTap = onTap
            self.onDoubleTap = onDoubleTap
            self.onLongPress = onLongPress
        }
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            onTap(gesture.location(in: gesture.view))
        }
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            onDoubleTap(gesture.location(in: gesture.view))
        }
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                onLongPress?(gesture.location(in: gesture.view))
            }
        }
    }
}
#elseif os(macOS)
private struct Representable: NSViewRepresentable {
    var onTap: (CGPoint) -> Void
    var onDoubleTap: (CGPoint) -> Void
    var onLongPress: ((CGPoint) -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap, onDoubleTap: onDoubleTap, onLongPress: onLongPress) }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        let single = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        single.numberOfClicksRequired = 1

        let double = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        double.numberOfClicksRequired = 2

        let press = NSPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))

        view.addGestureRecognizer(single)
        view.addGestureRecognizer(double)
        view.addGestureRecognizer(press)

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class Coordinator: NSObject {
        var onTap: (CGPoint) -> Void
        var onDoubleTap: (CGPoint) -> Void
        var onLongPress: ((CGPoint) -> Void)?
        init(onTap: @escaping (CGPoint) -> Void, onDoubleTap: @escaping (CGPoint) -> Void, onLongPress: ((CGPoint) -> Void)?) {
            self.onTap = onTap
            self.onDoubleTap = onDoubleTap
            self.onLongPress = onLongPress
        }
        @objc func handleTap(_ gesture: NSClickGestureRecognizer) {
            onTap(gesture.location(in: gesture.view))
        }
        @objc func handleDoubleTap(_ gesture: NSClickGestureRecognizer) {
            onDoubleTap(gesture.location(in: gesture.view))
        }
        @objc func handleLongPress(_ gesture: NSPressGestureRecognizer) {
            if gesture.state == .began {
                onLongPress?(gesture.location(in: gesture.view))
            }
        }
    }
}
#endif
