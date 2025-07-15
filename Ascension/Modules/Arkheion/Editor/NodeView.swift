import SwiftUI

/// Visual representation of a single node with an enlarged hit area.
struct NodeView: View {
    var node: Node
    var branchID: UUID
    var selected: Bool
    @Binding var selectedNodeID: UUID?
    @Binding var selectedBranchID: UUID?

    /// Padding applied around the node for hit testing.
    static let hitPadding: CGFloat = 20

    var body: some View {
        let base = ZStack {
            // Occlude branch lines behind the node
            Circle().fill(Color.black)
            if node.completed {
                Circle().fill(node.attribute.color)
            }
            Circle().stroke(Color.white, lineWidth: 2)
        }

        base
            .frame(width: node.size.radius * 2, height: node.size.radius * 2)
            .padding(Self.hitPadding)
            .contentShape(Rectangle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: selected ? 3 : 0)
            )
            .scaleEffect(selected ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: selected)
            .shadow(color: node.completed ? .clear : node.attribute.color,
                    radius: node.completed ? 0 : 6)
            .allowsHitTesting(true)
            .onTapGesture {
                selectedNodeID = node.id
                selectedBranchID = branchID
            }
    }
}

#if DEBUG
#Preview {
    NodeView(
        node: Node(),
        branchID: UUID(),
        selected: false,
        selectedNodeID: .constant(nil),
        selectedBranchID: .constant(nil)
    )
}
#endif
