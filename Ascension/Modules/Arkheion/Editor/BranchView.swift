import SwiftUI

/// Renders a branch and its nodes
struct BranchView: View {
    @Binding var branch: Branch
    var center: CGPoint
    var ringRadius: CGFloat
    @Binding var selectedBranchID: UUID?
    @Binding var selectedNodeID: UUID?
    var onAddNode: () -> Void = {}

    var body: some View {
        // Distance for the branch line extending past the ring
        let pathLength = CGFloat(branch.nodes.count + 1) * 60

        // Starting point of the branch at the ring's edge
        let origin = CGPoint(
            x: center.x + cos(branch.angle) * ringRadius,
            y: center.y + sin(branch.angle) * ringRadius
        )

        let branchPath = Path { path in
            path.move(to: origin)
            let end = CGPoint(
                x: origin.x + cos(branch.angle) * pathLength,
                y: origin.y + sin(branch.angle) * pathLength
            )
            path.addLine(to: end)
        }

        ZStack {
            branchPath
                .stroke(selectedBranchID == branch.id ? Color.white : Color.white.opacity(0.5), lineWidth: selectedBranchID == branch.id ? 4 : 2)
                .contentShape(branchPath.strokedPath(StrokeStyle(lineWidth: 20)))
                .zIndex(2)

            ForEach(Array(branch.nodes.enumerated()), id: \.1.id) { index, node in
                let distance = ringRadius + CGFloat(index + 1) * 60
                let position = CGPoint(
                    x: center.x + cos(branch.angle) * distance,
                    y: center.y + sin(branch.angle) * distance
                )

                Circle()
                    .fill(node.attribute.color)
                    .frame(width: node.size.radius * 2, height: node.size.radius * 2)
                    .padding(12)
                    .contentShape(Circle().inset(by: -12))
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: selectedNodeID == node.id ? 3 : 0)
                    )
                    .scaleEffect(selectedNodeID == node.id ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedNodeID == node.id)
                    .position(position)
                    .shadow(color: node.completed ? .clear : node.attribute.color, radius: node.completed ? 0 : 6)
            }

            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4]))
                .frame(width: 24, height: 24)
                .padding(10)
                .contentShape(Circle().inset(by: -10))
                .position(x: center.x + cos(branch.angle) * ringRadius,
                          y: center.y + sin(branch.angle) * ringRadius)
        }
        .contentShape(branchPath)
        .zIndex(1)
    }
}

#Preview {
    BranchView(
        branch: .constant(Branch(ringIndex: 0, angle: 0, nodes: [Node()])),
        center: CGPoint(x: 150, y: 150),
        ringRadius: 100,
        selectedBranchID: .constant(nil),
        selectedNodeID: .constant(nil)
    )
}
