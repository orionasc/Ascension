import SwiftUI

struct RingView: View {
    var ring: Ring
    var center: CGPoint
    var highlighted: Bool = false
    var selected: Bool = false

    private var strokeColor: Color {
        ring.locked ? Color.white.opacity(0.2) : Color.white.opacity(0.4)
    }

    var body: some View {
        ZStack {
            // Optional highlight ring (hover state)
            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 4)
                .frame(width: ring.radius * 2 + 8, height: ring.radius * 2 + 8)
                .opacity(highlighted ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: highlighted)

            // Main ring stroke
            Circle()
                .stroke(strokeColor, lineWidth: 2)
                .frame(width: ring.radius * 2, height: ring.radius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: selected ? 3 : 0)
                )
        }
        .position(center)
        .shadow(color: ring.locked ? .clear : Color.white.opacity(0.5), radius: ring.locked ? 0 : 4)
        .allowsHitTesting(true)
    }
}
