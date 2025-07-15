import SwiftUI

/// Toolbar displayed on the right side of ``ArkheionMapView`` giving quick
/// access to editing actions for rings, branches and nodes.
struct EditorToolbarView: View {
    // Binding collections so edits propagate to the map view
    @Binding var rings: [Ring]
    @Binding var branches: [Branch]

    /// Currently selected elements
    @Binding var selectedRingIndex: Int?
    @Binding var selectedBranchID: UUID?

    /// Show/Hide state for the toolbar
    @State private var expanded = true

    /// Callback actions provided by the host view
    var addRing: () -> Void = {}
    var unlockAllRings: () -> Void = {}
    var deleteRing: () -> Void = {}
    var createBranch: () -> Void = {}
    var deleteBranch: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            if expanded {
                content
                    .transition(.move(edge: .trailing))
            }

            toggleButton
        }
        .frame(maxHeight: .infinity, alignment: .topTrailing)
    }

    private var toggleButton: some View {
        Button(action: { withAnimation { expanded.toggle() } }) {
            Image(systemName: expanded ? "chevron.right" : "chevron.left")
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .padding(4)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ringControls
                Divider()
                branchControls
            }
            .padding()
        }
        .frame(width: 280)
        .background(.ultraThinMaterial)
    }

    // MARK: - Ring Controls
    private var ringControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ring Controls")
                .font(.headline)
            Button(action: addRing) {
                Label("Add Ring", systemImage: "plus.circle")
            }
            Button(action: unlockAllRings) {
                Label("Unlock All Rings", systemImage: "lock.open")
            }
            Button(role: .destructive, action: deleteRing) {
                Label("Delete Ring", systemImage: "trash")
            }
            .disabled(selectedRingIndex == nil)
            if let binding = bindingForRing(selectedRingIndex) {
                HStack {
                    Text("Radius")
                    Slider(value: binding.radius, in: 100...600)
                }
            }
        }
    }

    // MARK: - Branch Controls
    private var branchControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Branch Controls")
                .font(.headline)
            Button(action: createBranch) {
                Label("Create New Branch", systemImage: "line.diagonal.arrow")
            }
            if selectedBranchID != nil {
                Button(role: .destructive, action: deleteBranch) {
                    Label("Delete Branch", systemImage: "trash")
                }
            }
            /*
            Picker("Ring", selection: $selectedRingIndex) {
                Text("None").tag(Int?.none)
                ForEach(rings) { ring in
                    Text("Ring \(ring.ringIndex)").tag(Int?.some(ring.ringIndex))
                }
            }
            .pickerStyle(.menu)
            */

            // Placeholder for future branch-specific controls
        }
    }


    // MARK: - Helpers for bindings
    private func bindingForRing(_ index: Int?) -> Binding<Ring>? {
        guard let index else { return nil }
        guard let idx = rings.firstIndex(where: { $0.ringIndex == index }) else { return nil }
        return $rings[idx]
    }

    private func bindingForBranch(_ id: UUID?) -> Binding<Branch>? {
        guard let id else { return nil }
        guard let idx = branches.firstIndex(where: { $0.id == id }) else {
            DispatchQueue.main.async {
                selectedBranchID = nil
            }
            return nil
        }
        return $branches[idx]
    }

}

#Preview {
    EditorToolbarView(
        rings: .constant([Ring(ringIndex: 0, radius: 180, locked: false)]),
        branches: .constant([]),
        selectedRingIndex: .constant(nil),
        selectedBranchID: .constant(nil),
        deleteRing: {}
    )
}
