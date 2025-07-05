import SwiftUI

struct ModuleButtonView: View {
    var icon: String
    var label: String
    var active: Bool
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                pressed = false
            }
            action()
        } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.white.opacity(active ? 0.2 : 0.08))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(active ? Color.orange : Color.gray.opacity(0.4), lineWidth: 3)
                            .shadow(color: active ? Color.orange.opacity(0.6) : Color.clear, radius: active ? 6 : 0)
                    )
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(.white.opacity(active ? 1 : 0.5))
                    )
                    .scaleEffect(pressed ? 0.9 : 1.0)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(active ? 0.9 : 0.6))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ModuleButtonView(icon: "tray.full", label: "Arkheion", active: true) {}
}
