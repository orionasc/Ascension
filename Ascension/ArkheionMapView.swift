import SwiftUI

struct ArkheionMapView: View {
    struct Node: Identifiable {
        let id = UUID()
        var name: String
        var color: Color
        var angle: Double
    }

    private let nodes: [Node] = [
        Node(name: "Scholar", color: .blue, angle: 0),
        Node(name: "Sage", color: Color(red: 0.83, green: 0.67, blue: 0.22), angle: 2 * .pi / 3),
        Node(name: "Sovereign", color: Color(red: 0.80, green: 0.34, blue: 0.08), angle: 4 * .pi / 3)
    ]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) * 0.35

            ZStack {
                ForEach(nodes) { node in
                    NodeView(node: node) {
                        print(node.name)
                    }
                    .offset(x: radius * cos(node.angle), y: radius * sin(node.angle))
                }

                HeartSun()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: dismiss.callAsFunction) {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
    }
}

private struct NodeView: View {
    var node: ArkheionMapView.Node
    var action: () -> Void

    @State private var pressed = false
    @State private var hovering = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                pressed = false
            }
            action()
        }) {
            VStack(spacing: 4) {
                Circle()
                    .fill(node.color.opacity(0.8))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(node.color, lineWidth: 4)
                            .shadow(color: node.color.opacity(0.6), radius: 6)
                    )
                    .scaleEffect(pressed || hovering ? 1.1 : 1)
                Text(node.name)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
#if os(macOS)
        .onHover { hovering = $0 }
#endif
    }
}

private struct HeartSun: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.9))
                .frame(width: 120, height: 120)
                .shadow(color: Color.orange.opacity(0.4), radius: 40)

            Circle()
                .stroke(Color.orange.opacity(0.6), lineWidth: 6)
                .frame(width: 140, height: 140)
                .blur(radius: 2)
        }
    }
}

#Preview {
    ArkheionMapView()
}
