import SwiftUI

struct RadialNavMenuItem: Identifiable {
    let id = UUID()
    var icon: String
    var action: () -> Void
}

struct HalfCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.minY),
            radius: rect.width / 2,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: true
        )
        return path
    }
}

struct RadialNavMenuView: View {
    var items: [RadialNavMenuItem]

    @State private var visible = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                HalfCircle()
                    .fill(.ultraThinMaterial)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .shadow(radius: 2)

                ForEach(Array(items.enumerated()), id: \.1.id) { index, item in
                    let progress = Double(index) / Double(max(items.count - 1, 1))
                    let angle = Double.pi * (1 - progress)
                    let radius = geo.size.width / 2 * 0.75
                    let center = CGPoint(x: geo.size.width / 2, y: 0)
                    let x = center.x + radius * cos(angle)
                    let y = center.y + radius * sin(angle)

                    Button(action: item.action) {
                        Image(systemName: item.icon)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .foregroundColor(.white)
                    }
                    .position(x: x, y: y)
                    .scaleEffect(visible ? 1 : 0.9)
                    .opacity(visible ? 1 : 0)
                    .animation(
                        .easeOut(duration: 0.3).delay(Double(index) * 0.05),
                        value: visible
                    )
                }
            }
        }
        .frame(width: 300, height: 150)
        .opacity(visible ? 1 : 0)
#if os(macOS)
        .onHover { hovering in
            withAnimation { visible = hovering }
        }
#else
        .onTapGesture {
            withAnimation { visible.toggle() }
        }
#endif
    }
}

#if DEBUG
struct RadialNavMenuView_Previews: PreviewProvider {
    static var previews: some View {
        RadialNavMenuView(items: [
            RadialNavMenuItem(icon: "arrowshape.turn.up.left", action: {}),
            RadialNavMenuItem(icon: "sun.max", action: {}),
            RadialNavMenuItem(icon: "shield", action: {})
        ])
    }
}
#endif
