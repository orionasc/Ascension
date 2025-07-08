import SwiftUI

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

    private var strokeColor: Color {
        ring.locked ? Color.white.opacity(0.2) : Color.white.opacity(0.4)
    }

    var body: some View {
        Circle()
            .stroke(strokeColor, lineWidth: 2)
            .frame(width: ring.radius * 2, height: ring.radius * 2)
            .position(x: center.x, y: center.y)
            .shadow(color: ring.locked ? .clear : Color.white.opacity(0.5), radius: ring.locked ? 0 : 4)
            .onTapGesture(count: 2) {
                onDoubleTap(ring.ringIndex)
            }
            .onTapGesture {
                onTap(ring.ringIndex)
            }
            .onLongPressGesture {
                onLongPress(ring.ringIndex)
            }
    }
}

#Preview {
    ZStack {
        Color.black
        RingView(ring: Ring(ringIndex: 0, radius: 100, locked: false), center: CGPoint(x: 150, y: 150))
    }
}
