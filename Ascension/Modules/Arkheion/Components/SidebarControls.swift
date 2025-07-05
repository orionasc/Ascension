import SwiftUI

struct SidebarControls: View {
    var zoomIn: () -> Void
    var zoomOut: () -> Void
    var dragMode: Bool
    var toggleDragMode: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            controlButton(icon: "plus", action: zoomIn)
            controlButton(icon: "minus", action: zoomOut)
            controlButton(icon: "hand.draw", action: toggleDragMode, active: dragMode)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding()
    }

    private func controlButton(icon: String, action: @escaping () -> Void, active: Bool = false) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.15)))
                .overlay(
                    Circle()
                        .stroke(active ? Color.orange : Color.white.opacity(0.4), lineWidth: 2)
                )
                .shadow(color: active ? Color.orange.opacity(0.7) : Color.clear, radius: active ? 5 : 0)
                .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
struct SidebarControls_Previews: PreviewProvider {
    static var previews: some View {
        SidebarControls(zoomIn: {}, zoomOut: {}, dragMode: true, toggleDragMode: {})
    }
}
#endif
