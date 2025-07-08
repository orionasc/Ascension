import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Data model representing a single concentric ring in the Arkheion map.
struct Ring: Identifiable {
    let id = UUID()
    var ringIndex: Int
    var radius: CGFloat
    var locked: Bool
}

/// Visual representation of a single ring.
struct RingView: View {
    var ring: Ring
    var center: CGPoint
    var onTap: (Int) -> Void = { _ in }
    var onLongPress: (Int) -> Void = { _ in }
    var onDoubleTap: (Int) -> Void = { _ in }
    @State private var isHighlighted = false

    private var strokeColor: Color {
        ring.locked ? Color.white.opacity(0.2) : Color.white.opacity(0.4)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 4)
                .frame(width: ring.radius * 2 + 8, height: ring.radius * 2 + 8)
                .opacity(isHighlighted ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: isHighlighted)

            Circle()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: ring.radius * 2, height: ring.radius * 2)
        }
        .padding(20)
        .contentShape(Circle().inset(by: -20))
        .position(x: center.x, y: center.y)
        .shadow(color: ring.locked ? .clear : Color.white.opacity(0.5), radius: ring.locked ? 0 : 4)
        .onTapGesture(count: 2) {
            highlight();
            onDoubleTap(ring.ringIndex)
        }
        .onTapGesture {
            highlight();
            onTap(ring.ringIndex)
        }
        .onLongPressGesture {
            highlight();
            onLongPress(ring.ringIndex)
        }
    }

    private func highlight() {
#if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
        isHighlighted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isHighlighted = false
        }
    }
}

#Preview {
    ZStack {
        Color.black
        RingView(ring: Ring(ringIndex: 0, radius: 100, locked: false), center: CGPoint(x: 150, y: 150))
    }
}
