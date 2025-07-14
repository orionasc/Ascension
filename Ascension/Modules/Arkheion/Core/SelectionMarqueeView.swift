import SwiftUI

/// Draws the rectangular selection marquee during drag operations.
struct SelectionMarqueeView: View {
    var start: CGPoint
    var current: CGPoint

    private var rect: CGRect {
        CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
    }

    var body: some View {
        Rectangle()
            .fill(Color.blue.opacity(0.15))
            .overlay(
                Rectangle()
                    .strokeBorder(Color.blue,
                                  style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
    }
}

