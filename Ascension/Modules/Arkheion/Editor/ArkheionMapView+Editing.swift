import SwiftUI

extension ArkheionMapView {
    // MARK: - Interaction
    fileprivate func onRingTapped(ringIndex: Int, angle: Double) {
        print("[ArkheionMap] Ring tapped: index=\(ringIndex) angle=\(angle)")
        selectedRingIndex = ringIndex
        selectedBranchID = nil
        selectedNodeID = nil
        print("[ArkheionMap] Selected ring: \(ringIndex)")
        guard let ring = store.rings.first(where: { $0.ringIndex == ringIndex }), !ring.locked else { return }
        var branch = Branch(ringIndex: ringIndex, angle: angle)
        let node = Node()
        branch.nodes.insert(node, at: 0)
        var updatedBranches = store.branches
        updatedBranches.append(branch)
        store.branches = updatedBranches
        selectedBranchID = branch.id
        selectedNodeID = node.id
        print("[ArkheionMap] Selected branch: \(branch.id)")
        print("[ArkheionMap] Selected node: \(node.id)")
        syncSelectionSets()
    }

    fileprivate func toggleLock(for ringIndex: Int) {
        if let index = store.rings.firstIndex(where: { $0.ringIndex == ringIndex }) {
            var updatedRings = store.rings
            updatedRings[index].locked.toggle()
            store.rings = updatedRings
        }
    }

    fileprivate func bindingForRing(_ index: Int) -> Binding<Ring>? {
        guard let idx = store.rings.firstIndex(where: { $0.ringIndex == index }) else { return nil }
        return $store.rings[idx]
    }

    fileprivate func addRing() {
        let nextIndex = (store.rings.map { $0.ringIndex }.max() ?? 0) + 1
        let baseRadius = (store.rings.map { $0.radius }.max() ?? 100) + 80
        var updatedRings = store.rings
        updatedRings.append(Ring(ringIndex: nextIndex, radius: baseRadius, locked: true))
        store.rings = updatedRings
        print("[ArkheionMap] Added ring index=\(nextIndex)")
    }

    fileprivate func deleteSelectedRing() {
        guard let ringIndex = selectedRingIndex else { return }
        guard store.rings.count > 1 else { return }
        var updatedRings = store.rings
        updatedRings.removeAll { $0.ringIndex == ringIndex }
        store.rings = updatedRings
        var updatedBranches = store.branches
        updatedBranches.removeAll { $0.ringIndex == ringIndex }
        store.branches = updatedBranches
        if editingRing?.ringIndex == ringIndex { editingRing = nil }
        selectedRingIndex = nil
        selectedBranchID = nil
        selectedNodeID = nil
        syncSelectionSets()
    }

    fileprivate func addNode(to branchID: UUID) {
        let branchIDs = store.branches.map { $0.id }
        print("[ArkheionMap] addNode -> selectedBranchID=\(String(describing: selectedBranchID))")
        print("[ArkheionMap] Current branches: \(branchIDs)")
        guard let index = store.branches.firstIndex(where: { $0.id == branchID }) else {
            print("[ArkheionMap] addNode aborted: branch \(branchID) not found")
            return
        }
        let node = Node()
        var updatedBranches = store.branches
        updatedBranches[index].nodes.insert(node, at: 0)
        store.branches = updatedBranches
        selectedNodeID = node.id
        print("[ArkheionMap] Added node to branch \(branchID)")
        syncSelectionSets()
    }

    fileprivate func unlockAllRings() {
        var updatedRings = store.rings
        for index in updatedRings.indices {
            updatedRings[index].locked = false
        }
        store.rings = updatedRings
    }

    fileprivate func resetCanvas() {
        store.branches.removeAll()
        store.rings.removeAll()
        store.rings.append(Ring(ringIndex: 0, radius: 100, locked: true))
        store.rings.append(Ring(ringIndex: 1, radius: 180, locked: true))
        selectedRingIndex = nil
        selectedBranchID = nil
        selectedNodeID = nil
        editingRing = nil
        syncSelectionSets()
    }

    fileprivate func createBranch(at angle: Double) {
        guard let ringIndex = selectedRingIndex else { return }
        var branch = Branch(ringIndex: ringIndex, angle: angle)
        let node = Node()
        branch.nodes.insert(node, at: 0)
        var updatedBranches = store.branches
        updatedBranches.append(branch)
        store.branches = updatedBranches
        selectedBranchID = branch.id
        selectedNodeID = node.id
        syncSelectionSets()
    }

    fileprivate func createBranchFromToolbar() {
        guard selectedRingIndex != nil else {
            print("[ArkheionMap] Cannot create branch: no ring selected")
            return
        }
        createBranch(at: 0.0)
    }

    fileprivate func addNodeFromToolbar() {
        guard let branchID = selectedBranchID else {
            print("[ArkheionMap] addNodeFromToolbar called with no branch selected")
            return
        }
        guard store.branches.contains(where: { $0.id == branchID }) else {
            print("[ArkheionMap] addNodeFromToolbar aborted: selected branch \(branchID) missing")
            selectedBranchID = nil
            return
        }
        addNode(to: branchID)
    }

    fileprivate func deleteSelectedBranch() {
        guard let id = selectedBranchID else { return }
        var updatedBranches = store.branches
        updatedBranches.removeAll { $0.id == id }
        store.branches = updatedBranches
        selectedBranchID = nil
        selectedNodeID = nil
        syncSelectionSets()
    }

    fileprivate func deleteSelectedNode() {
        guard let branchID = selectedBranchID, let nodeID = selectedNodeID else { return }
        guard let bIndex = store.branches.firstIndex(where: { $0.id == branchID }) else { return }
        var updatedBranches = store.branches
        updatedBranches[bIndex].nodes.removeAll { $0.id == nodeID }
        store.branches = updatedBranches
        selectedNodeID = nil
        syncSelectionSets()
    }

    fileprivate func moveSelectedNodeUp() {
        guard let branchID = selectedBranchID, let nodeID = selectedNodeID else { return }
        guard let bIndex = store.branches.firstIndex(where: { $0.id == branchID }) else { return }
        guard let nIndex = store.branches[bIndex].nodes.firstIndex(where: { $0.id == nodeID }), nIndex > 0 else { return }
        var updatedBranches = store.branches
        updatedBranches[bIndex].nodes.swapAt(nIndex, nIndex - 1)
        store.branches = updatedBranches
    }

    fileprivate func moveSelectedNodeDown() {
        guard let branchID = selectedBranchID, let nodeID = selectedNodeID else { return }
        guard let bIndex = store.branches.firstIndex(where: { $0.id == branchID }) else { return }
        guard let nIndex = store.branches[bIndex].nodes.firstIndex(where: { $0.id == nodeID }), nIndex < store.branches[bIndex].nodes.count - 1 else { return }
        var updatedBranches = store.branches
        updatedBranches[bIndex].nodes.swapAt(nIndex, nIndex + 1)
        store.branches = updatedBranches
    }

    /// Calculates completion progress for a ring based on nodes finished.
    fileprivate func progress(for ringIndex: Int) -> Double {
        let ringBranches = store.branches.filter { $0.ringIndex == ringIndex }
        let nodes = ringBranches.flatMap { $0.nodes }
        guard !nodes.isEmpty else { return 0 }
        let completed = nodes.filter { $0.completed }.count
        return Double(completed) / Double(nodes.count)
    }
}
