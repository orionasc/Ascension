import SwiftUI

/// Draws radial and concentric grid lines that move with the map content.
struct GridOverlayView: View {
    /// The overall size of the parent container. This allows the grid
    /// to align with other layers which use the same geometry reader.
    let size: CGSize
    /// The shared center point of the grid and the rest of the map.
    let center: CGPoint

    private let baseSpacing: CGFloat = 80
    private let segmentCount = 12

    var body: some View {
        Canvas { context, _ in
            let maxRadius = hypot(size.width, size.height) * 2

            // Concentric rings
            var radius: CGFloat = baseSpacing
            while radius <= maxRadius {
                var path = Path()
                path.addEllipse(in: CGRect(x: center.x - radius,
                                           y: center.y - radius,
                                           width: radius * 2,
                                           height: radius * 2))
                let alpha = 0.2 * (1.0 - (radius / maxRadius))
                context.stroke(path, with: .color(Color.white.opacity(alpha)), lineWidth: 0.5)
                radius += baseSpacing
            }

            // Radial segments
            for i in 0..<segmentCount {
                let angle = Double(i) / Double(segmentCount) * 2 * .pi
                var path = Path()
                path.move(to: center)
                path.addLine(to: CGPoint(x: center.x + CGFloat(Darwin.cos(angle)) * maxRadius,
                                         y: center.y + CGFloat(Darwin.sin(angle)) * maxRadius))
                context.stroke(path, with: .color(Color.white.opacity(0.2)), lineWidth: 0.5)
            }
        }
        .drawingGroup()
        .frame(width: size.width, height: size.height)
        .ignoresSafeArea()
    }
}

#if DEBUG
#Preview {
    GridOverlayView(size: CGSize(width: 300, height: 300),
                    center: CGPoint(x: 150, y: 150))
}
#endif
