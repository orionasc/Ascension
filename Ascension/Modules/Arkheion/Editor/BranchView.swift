import SwiftUI

/// Renders a branch and its nodes
struct BranchView: View {
    @Binding var branch: Branch
    var center: CGPoint
    var ringRadius: CGFloat
    var onAddNode: () -> Void = {}
    @State private var selectedNode: Node?

    var body: some View {
        let pathLength = ringRadius + CGFloat(branch.nodes.count + 1) * 60

        ZStack {
            Path { path in
                path.move(to: center)
                let end = CGPoint(
                    x: center.x + cos(branch.angle) * pathLength,
                    y: center.y + sin(branch.angle) * pathLength
                )
                path.addLine(to: end)
            }
            .stroke(Color.white.opacity(0.5), lineWidth: 2)

            ForEach(Array(branch.nodes.enumerated()), id: \.1.id) { index, node in
                let distance = ringRadius + CGFloat(index + 1) * 60
                let position = CGPoint(
                    x: center.x + cos(branch.angle) * distance,
                    y: center.y + sin(branch.angle) * distance
                )

                Circle()
                    .fill(node.attribute.color)
                    .frame(width: node.size.radius * 2, height: node.size.radius * 2)
                    .position(position)
                    .shadow(color: node.completed ? .clear : node.attribute.color, radius: node.completed ? 0 : 6)
                    .onTapGesture { selectedNode = branch.nodes[index] }
            }

            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4]))
                .frame(width: 24, height: 24)
                .position(x: center.x + cos(branch.angle) * ringRadius,
                          y: center.y + sin(branch.angle) * ringRadius)
                .onTapGesture { onAddNode() }
        }
        .sheet(item: $selectedNode) { idx in
            if let index = branch.nodes.firstIndex(where: { $0.id == idx.id }) {
                NodeEditorView(node: $branch.nodes[index])
            }
        }
    }
}

#Preview {
    BranchView(branch: .constant(Branch(ringIndex: 0, angle: 0, nodes: [Node()])), center: CGPoint(x: 150, y: 150), ringRadius: 100)
}
