import SwiftUI

struct ArkheionMapView: View {
    @EnvironmentObject private var progressModel: ArkheionProgressModel
    @Environment(\.dismiss) private var dismiss
    @State private var editNode: ArkheionNode?

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) * 0.35

            ZStack {
                ForEach(Array(progressModel.nodes.enumerated()), id: \.element.id) { index, node in
                    let angle = Double(index) / Double(max(progressModel.nodes.count, 1)) * 2 * .pi
                    NodeView(node: node,
                            onTap: { print(node.title) },
                            onEdit: { editNode = node },
                            onDelete: { progressModel.deleteNode(with: node.id) })
                    .offset(x: radius * cos(angle), y: radius * sin(angle))
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
        .sheet(item: $editNode) { node in
            NodeEditView(node: node)
        }
    }
}

private struct NodeView: View {
    var node: ArkheionNode
    var onTap: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

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
            onTap()
        }) {
            VStack(spacing: 4) {
                Circle()
                    .fill(nodeColor.opacity(0.8))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(nodeColor, lineWidth: 4)
                            .shadow(color: nodeColor.opacity(0.6), radius: 6)
                    )
                    .scaleEffect(pressed || hovering ? 1.1 : 1)
                Text(node.title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
#if os(macOS)
        .onHover { hovering = $0 }
#endif
        .nodeContextMenu(onEdit: onEdit, onDelete: onDelete)
    }

    private var nodeColor: Color {
        switch node.archetype {
        case "Scholar": return .blue
        case "Sage": return Color(red: 0.83, green: 0.67, blue: 0.22)
        case "Sovereign": return Color(red: 0.80, green: 0.34, blue: 0.08)
        default: return .accentColor
        }
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
        .environmentObject(ArkheionProgressModel())
}
