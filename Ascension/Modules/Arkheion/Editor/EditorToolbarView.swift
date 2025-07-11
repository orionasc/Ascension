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
    @Binding var selectedNodeID: UUID?

    /// Show/Hide state for the toolbar
    @State private var expanded = true

    /// Callback actions provided by the host view
    var addRing: () -> Void = {}
    var unlockAllRings: () -> Void = {}
    var deleteRing: () -> Void = {}
    var createBranch: () -> Void = {}
    var addNode: () -> Void = {}
    var deleteBranch: () -> Void = {}
    var deleteNode: () -> Void = {}
    var moveNodeUp: () -> Void = {}
    var moveNodeDown: () -> Void = {}

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
                Divider()
                nodeControls
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

            if let branchBinding = bindingForBranch(selectedBranchID) {
                VStack(alignment: .leading) {
                    Text("Themes")
                    themeGrid(for: branchBinding)
                }
            }
        }
    }

    // MARK: - Node Controls
    private var nodeControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Node Controls")
                .font(.headline)
            Button(action: addNode) {
                Label("Add Node", systemImage: "plus")
            }
            .disabled(selectedBranchID == nil)
            if selectedNodeID != nil {
                HStack {
                    Button(action: moveNodeUp) {
                        Image(systemName: "arrow.up")
                    }
                    Button(action: moveNodeDown) {
                        Image(systemName: "arrow.down")
                    }
                }
                Button(role: .destructive, action: deleteNode) {
                    Label("Delete Node", systemImage: "trash")
                }
            }
            if let nodeBinding = bindingForNode(selectedNodeID, branchID: selectedBranchID) {
                Picker("Type", selection: nodeBinding.type) {
                    ForEach(NodeType.allCases) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                Picker("Attribute", selection: nodeBinding.attribute) {
                    ForEach(NodeAttribute.allCases) { attr in
                        Text(attr.rawValue.capitalized).tag(attr)
                    }
                }
                Picker("Size", selection: nodeBinding.size) {
                    ForEach(NodeSize.allCases) { size in
                        Text(size.rawValue.capitalized).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                TextField("Title", text: nodeBinding.title)
                TextField("Description", text: nodeBinding.description)
                Toggle("Completed", isOn: nodeBinding.completed)
            }
        }
    }

    private func themeGrid(for branch: Binding<Branch>) -> some View {
        let selection = branch.themes
        return LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3)) {
            ForEach(NodeAttribute.allCases) { attr in
                Button {
                    toggle(attr, in: branch)
                } label: {
                    Circle()
                        .fill(attr.color)
                        .overlay(
                            Image(systemName: selection.wrappedValue.contains(attr) ? "checkmark" : "")
                                .foregroundColor(.black)
                        )
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .disabled(!selection.wrappedValue.contains(attr) && selection.wrappedValue.count >= 3)
            }
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
        guard let idx = branches.firstIndex(where: { $0.id == id }) else { return nil }
        return $branches[idx]
    }

    private func bindingForNode(_ id: UUID?, branchID: UUID?) -> Binding<Node>? {
        guard let id, let branchBinding = bindingForBranch(branchID) else { return nil }
        guard let idx = branchBinding.nodes.wrappedValue.firstIndex(where: { $0.id == id }) else { return nil }
        return branchBinding.nodes[idx]
    }

    private func toggle(_ attr: NodeAttribute, in branch: Binding<Branch>) {
        if branch.themes.wrappedValue.contains(attr) {
            branch.themes.wrappedValue.removeAll { $0 == attr }
        } else if branch.themes.wrappedValue.count < 3 {
            branch.themes.wrappedValue.append(attr)
        }
    }
}

#Preview {
    EditorToolbarView(
        rings: .constant([Ring(ringIndex: 0, radius: 180, locked: false)]),
        branches: .constant([]),
        selectedRingIndex: .constant(nil),
        selectedBranchID: .constant(nil),
        selectedNodeID: .constant(nil),
        deleteRing: {}
    )
}
