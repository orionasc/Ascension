import SwiftUI

struct ArkheionMapView: View {
    @EnvironmentObject private var progressModel: ArkheionProgressModel
    @Environment(\.dismiss) private var dismiss
    @State private var editNode: ArkheionNode?

    private let archetypes = ["Scholar", "Sage", "Sovereign"]
    @State private var expanded: [String: Bool] = ["Scholar": false, "Sage": false, "Sovereign": false]
    @State private var knownNodeIDs: Set<UUID> = []
    @State private var newlyAddedIDs: Set<UUID> = []

    @ViewBuilder
    private func archetypeViews(radius: CGFloat, subRadius: CGFloat) -> some View {
        ForEach(Array(archetypes.enumerated()), id: \.element) { index, archetype in
            let rootAngle = Double(index) / Double(archetypes.count) * 2 * .pi

            RootNodeView(archetype: archetype, isExpanded: expanded[archetype] ?? false) {
                withAnimation(.spring()) { expanded[archetype]?.toggle() }
            }
            .offset(x: radius * cos(rootAngle), y: radius * sin(rootAngle))

            if expanded[archetype] ?? false {
                let nodes = progressModel.nodes.filter { $0.archetype == archetype }
                ForEach(Array(nodes.enumerated()), id: \.element.id) { subIndex, node in
                    let arcRange = Double.pi / 2
                    let startAngle = rootAngle - arcRange / 2
                    let angle = startAngle + arcRange * Double(subIndex) / Double(max(nodes.count - 1, 1))
                    NodeView(node: node,
                            isNew: newlyAddedIDs.contains(node.id),
                            appearDelay: Double(subIndex) * 0.05,
                            onTap: { print(node.title) },
                            onEdit: { editNode = node },
                            onDelete: { progressModel.deleteNode(with: node.id) },
                            onAppearDone: { newlyAddedIDs.remove(node.id) })
                    .offset(x: radius * cos(rootAngle) + subRadius * cos(angle),
                            y: radius * sin(rootAngle) + subRadius * sin(angle))
                }
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) * 0.35
            let subRadius = radius * 0.6

            ZStack {
                archetypeViews(radius: radius, subRadius: subRadius)
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
        .onChange(of: progressModel.nodes) { nodes in
            let ids = Set(nodes.map(\.id))
            let added = ids.subtracting(knownNodeIDs)
            newlyAddedIDs.formUnion(added)
            knownNodeIDs = ids
        }
    }
}

private struct NodeView: View {
    var node: ArkheionNode
    var isNew: Bool = false
    var appearDelay: Double = 0
    var onTap: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onAppearDone: () -> Void = {}

    @State private var pressed = false
    @State private var hovering = false
    @State private var appeared = false
    @State private var highlight = false
    @State private var show = false

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
                    .overlay(
                        Circle()
                            .stroke(nodeColor, lineWidth: 6)
                            .scaleEffect(highlight ? 1.4 : 1.2)
                            .opacity(highlight ? 0.8 : 0)
                    )
                    .scaleEffect(show ? (pressed || hovering ? 1.1 : 1) : 0.3)
                    .opacity(show ? 1 : 0)
                Text(node.title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
#if os(macOS)
        .onHover { hovering = $0 }
#endif
        .onAppear {
            guard !appeared else { return }
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + appearDelay) {
                withAnimation(.spring()) { show = true }
                if isNew {
                    highlight = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        highlight = false
                    }
                }
                onAppearDone()
            }
        }
        .animation(.easeOut(duration: 0.7), value: highlight)
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

private struct RootNodeView: View {
    var archetype: String
    var isExpanded: Bool
    var action: () -> Void

    private var color: Color {
        switch archetype {
        case "Scholar": return .blue
        case "Sage": return Color(red: 0.83, green: 0.67, blue: 0.22)
        case "Sovereign": return Color(red: 0.80, green: 0.34, blue: 0.08)
        default: return .accentColor
        }
    }

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color.opacity(0.8))
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: isExpanded ? 6 : 4)
                        .shadow(color: color.opacity(0.6), radius: isExpanded ? 8 : 6)
                )
                .overlay(
                    Text(String(archetype.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )
        }
        .buttonStyle(.plain)
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
