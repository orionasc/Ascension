import SwiftUI

struct RadialNavMenuItem: Identifiable {
    let id = UUID()
    var icon: String
    var action: () -> Void
}

struct RadialNavMenu: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    var items: [RadialNavMenuItem]
    @State private var show = false

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 5
            ZStack {
                ForEach(Array(items.enumerated()), id: \.1.id) { index, item in
                    let progress = Double(index) / Double(max(items.count - 1, 1))
                    let angle = Double.pi * (1 - progress)
                    let x = radius * cos(angle)
                    let y = radius * sin(angle)

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
                    .position(x: geo.size.width / 2 + x,
                              y: safeAreaInsets.top + 30 + y)
                    .scaleEffect(show ? 1 : 0.5)
                    .opacity(show ? 1 : 0)
                    .animation(
                        .easeOut(duration: 0.4).delay(Double(index) * 0.05),
                        value: show
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .allowsHitTesting(true)
        .onAppear { show = true }
    }
}

#if DEBUG
struct RadialNavMenu_Previews: PreviewProvider {
    static var previews: some View {
        RadialNavMenu(items: [
            RadialNavMenuItem(icon: "arrowshape.turn.up.left", action: {}),
            RadialNavMenuItem(icon: "sun.max", action: {}),
            RadialNavMenuItem(icon: "shield", action: {})
        ])
    }
}
#endif
