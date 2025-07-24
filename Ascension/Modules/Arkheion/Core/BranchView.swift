import SwiftUI

struct BranchView: View {
    @Binding var branch: Branch
    var center: CGPoint
    var ringRadius: CGFloat

    @Binding var selectedBranchID: UUID?
    @Binding var selectedNodeID: UUID?
    var onAddNode: () -> Void = {}

    @State private var hoveringBase = false

    var isSelected: Bool {
        selectedBranchID == branch.id
    }

    var body: some View {
        let origin = CGPoint(
            x: center.x + cos(branch.angle) * ringRadius,
            y: center.y + sin(branch.angle) * ringRadius
        )

        let direction = CGPoint(x: cos(branch.angle), y: sin(branch.angle))

        let path = Path { path in
            var current = origin
            for (i, node) in branch.nodes.enumerated() {
                let nextDistance = ringRadius + CGFloat(i + 1) * 60
                let next = CGPoint(
                    x: center.x + direction.x * nextDistance,
                    y: center.y + direction.y * nextDistance
                )
                path.move(to: current)
                path.addLine(to: next)
                current = next
            }
        }

        ZStack {
            path
                .stroke(isSelected ? Color.white : Color.white.opacity(0.5),
                        lineWidth: isSelected ? 4 : 2)
                .contentShape(path.strokedPath(StrokeStyle(lineWidth: 20)))
                .onTapGesture {
                    selectedBranchID = branch.id
                    selectedNodeID = nil
                }

            ForEach(Array(branch.nodes.enumerated()), id: \.1.id) { index, node in
                let distance = ringRadius + CGFloat(index + 1) * 60
                let position = CGPoint(
                    x: center.x + direction.x * distance,
                    y: center.y + direction.y * distance
                )

                NodeView(
                    node: node,
                    branchID: branch.id,
                    selected: selectedNodeID == node.id,
                    selectedNodeID: $selectedNodeID,
                    selectedBranchID: $selectedBranchID
                )
                .position(position)
            }

            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4]))
                .frame(width: 24, height: 24)
                .padding(10)
                .opacity(hoveringBase ? 1 : 0)
                .contentShape(Circle().inset(by: -10))
                .position(origin)
                .onTapGesture(perform: onAddNode)
                .onHover { hovering in
                    hoveringBase = hovering
                }
        }
        .zIndex(1)
    }
}
