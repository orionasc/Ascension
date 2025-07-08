import SwiftUI

/// Floating panel for editing a ring. Can be dragged around the screen.
struct FloatingRingEditorView: View {
    @Binding var ring: Ring
    var progress: Double
    var onBack: () -> Void

    @State private var offset: CGSize = .zero
    @GestureState private var dragState: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .padding(4)
                }
                Spacer()
            }

            Button(action: { ring.locked.toggle() }) {
                Label(ring.locked ? "Locked" : "Unlocked",
                      systemImage: ring.locked ? "lock.fill" : "lock.open")
                    .foregroundColor(ring.locked ? .gray : .green)
            }
            .buttonStyle(.bordered)

            HStack {
                Text("Radius")
                Slider(value: $ring.radius, in: 100...600)
            }

            ProgressView(value: progress) {
                Text("Progress")
            }
            .progressViewStyle(.linear)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .offset(x: offset.width + dragState.width,
                y: offset.height + dragState.height)
        .gesture(
            DragGesture()
                .updating($dragState) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    offset.width += value.translation.width
                    offset.height += value.translation.height
                }
        )
        .frame(maxWidth: 300)
    }
}

#if DEBUG
struct FloatingRingEditorView_Previews: PreviewProvider {
    static var previews: some View {
        FloatingRingEditorView(
            ring: .constant(Ring(ringIndex: 0, radius: 200, locked: false)),
            progress: 0.5,
            onBack: {}
        )
    }
}
#endif
