import SwiftUI

/// Draws radial and concentric grid lines that move with the map content.
struct GridOverlayView: View {

    private let baseSpacing: CGFloat = 80
    private let segmentCount = 12

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxRadius = hypot(size.width, size.height) * 2

                // Determine spacing between rings so it appears constant
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
                    path.addLine(to: CGPoint(x: center.x + cos(angle) * maxRadius,
                                             y: center.y + sin(angle) * maxRadius))
                    context.stroke(path, with: .color(Color.white.opacity(0.2)), lineWidth: 0.5)
                }
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
    }
}

#if DEBUG
#Preview {
    GridOverlayView()
        .frame(width: 300, height: 300)
}
#endif
