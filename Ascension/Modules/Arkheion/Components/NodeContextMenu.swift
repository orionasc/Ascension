import SwiftUI

struct NodeContextMenu: ViewModifier {
    var onEdit: () -> Void
    var onDelete: () -> Void
    @State private var showConfirm = false

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button("Edit Node", action: onEdit)
                Button("Delete Node", role: .destructive) { showConfirm = true }
            }
            .confirmationDialog("Delete this node?", isPresented: $showConfirm) {
                Button("Delete", role: .destructive, action: onDelete)
                Button("Cancel", role: .cancel) {}
            }
    }
}

extension View {
    func nodeContextMenu(onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) -> some View {
        modifier(NodeContextMenu(onEdit: onEdit, onDelete: onDelete))
    }
}
