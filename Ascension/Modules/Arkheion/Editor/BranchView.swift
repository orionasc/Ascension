import SwiftUI

/// Renders a branch
struct BranchView: View {
    @Binding var branch: Branch
    var center: CGPoint
    var ringRadius: CGFloat
    @Binding var selectedBranchID: UUID?
    var onTap: (() -> Void)? = nil

    var body: some View {
        // Starting point of the branch at the ring's edge
        let origin = CGPoint(
            x: center.x + CGFloat(Darwin.cos(branch.angle)) * ringRadius,
            y: center.y + CGFloat(Darwin.sin(branch.angle)) * ringRadius
        )

        let direction = CGPoint(x: CGFloat(Darwin.cos(branch.angle)),
                                y: CGFloat(Darwin.sin(branch.angle)))

        let end = CGPoint(
            x: center.x + direction.x * (ringRadius + 60),
            y: center.y + direction.y * (ringRadius + 60)
        )
        let branchPath = Path { path in
            path.move(to: origin)
            path.addLine(to: end)
        }

        ZStack {
            branchPath
                .stroke(
                    selectedBranchID == branch.id ? Color.white : Color.white.opacity(0.5),
                    lineWidth: selectedBranchID == branch.id ? 4 : 2
                )
                .contentShape(branchPath.strokedPath(StrokeStyle(lineWidth: 20)))
                .zIndex(2)
        }
        .contentShape(Rectangle())
        .allowsHitTesting(true)
        .onTapGesture {
            onTap?()
        }
        .zIndex(1)
    }
}

#Preview {
    BranchView(
        branch: .constant(Branch(ringIndex: 0, angle: 0)),
        center: CGPoint(x: 150, y: 150),
        ringRadius: 100,
        selectedBranchID: .constant(nil)
    )
}
