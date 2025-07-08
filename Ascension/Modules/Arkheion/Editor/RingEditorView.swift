import SwiftUI

/// Editor for adjusting ring properties
struct RingEditorView: View {
    @Binding var ring: Ring
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Locked", isOn: $ring.locked)
                HStack {
                    Text("Radius")
                    Slider(value: $ring.radius, in: 100...600)
                }
            }
            .navigationTitle("Edit Ring")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    RingEditorView(ring: .constant(Ring(ringIndex: 0, radius: 200, locked: false)))
}
