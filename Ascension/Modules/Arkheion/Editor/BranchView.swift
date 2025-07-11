import SwiftUI

/// Renders a branch and its nodes
struct BranchView: View {
    @Binding var branch: Branch
    var center: CGPoint
    var ringRadius: CGFloat
    @Binding var selectedBranchID: UUID?
    @Binding var selectedNodeID: UUID?
    var onAddNode: () -> Void = {}

    /// When hovering the base of the branch we show the dashed add control
    @State private var hoveringBase = false

    var body: some View {
        // Starting point of the branch at the ring's edge
        let origin = CGPoint(
            x: center.x + CGFloat(Darwin.cos(branch.angle)) * ringRadius,
            y: center.y + CGFloat(Darwin.sin(branch.angle)) * ringRadius
        )

        let direction = CGPoint(x: CGFloat(Darwin.cos(branch.angle)),
                                y: CGFloat(Darwin.sin(branch.angle)))

        let branchPath = Path { path in
            var start = origin
            var startRadius: CGFloat = 0
            for (index, node) in branch.nodes.enumerated() {
                let distance = ringRadius + CGFloat(index + 1) * 60
                let position = CGPoint(
                    x: center.x + direction.x * distance,
                    y: center.y + direction.y * distance
                )
                let segmentStart = CGPoint(
                    x: start.x + direction.x * startRadius,
                    y: start.y + direction.y * startRadius
                )
                let segmentEnd = CGPoint(
                    x: position.x - direction.x * node.size.radius,
                    y: position.y - direction.y * node.size.radius
                )
                path.move(to: segmentStart)
                path.addLine(to: segmentEnd)
                start = position
                startRadius = node.size.radius
            }
        }

        ZStack {
            branchPath
                .stroke(selectedBranchID == branch.id ? Color.white : Color.white.opacity(0.5), lineWidth: selectedBranchID == branch.id ? 4 : 2)
                .contentShape(branchPath.strokedPath(StrokeStyle(lineWidth: 20)))
                .zIndex(2)

            ForEach(Array(branch.nodes.enumerated()), id: \.1.id) { index, node in
                let distance = ringRadius + CGFloat(index + 1) * 60
                let position = CGPoint(
                    x: center.x + CGFloat(Darwin.cos(branch.angle)) * distance,
                    y: center.y + CGFloat(Darwin.sin(branch.angle)) * distance
                )

                NodeView(node: node, selected: selectedNodeID == node.id)
                    .position(position)
            }

            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4]))
                .frame(width: 24, height: 24)
                .padding(10)
                .opacity(hoveringBase ? 1 : 0)
                .contentShape(Circle().inset(by: -10))
                .position(x: center.x + CGFloat(Darwin.cos(branch.angle)) * ringRadius,
                          y: center.y + CGFloat(Darwin.sin(branch.angle)) * ringRadius)
                .onTapGesture(perform: onAddNode)
                .onHover { hovering in
                    hoveringBase = hovering
                }
        }
        .contentShape(Rectangle())
        .allowsHitTesting(true)
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
