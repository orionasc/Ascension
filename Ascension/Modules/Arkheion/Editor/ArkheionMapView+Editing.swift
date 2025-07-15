import SwiftUI

extension ArkheionMapView {
    // MARK: - Interaction
    func onRingTapped(ringIndex: Int, angle: Double) {
        print("[ArkheionMap] Ring tapped: index=\(ringIndex) angle=\(angle)")
        selectedRingIndex = ringIndex
        selectedBranchID = nil
        print("[ArkheionMap] Selected ring: \(ringIndex)")
        guard let ring = store.rings.first(where: { $0.ringIndex == ringIndex }), !ring.locked else { return }
        var branch = Branch(ringIndex: ringIndex, angle: angle)
        var updatedBranches = store.branches
        updatedBranches.append(branch)
        store.branches = updatedBranches
        selectedBranchID = branch.id
        print("[ArkheionMap] Selected branch: \(branch.id)")
    }

    func toggleLock(for ringIndex: Int) {
        if let index = store.rings.firstIndex(where: { $0.ringIndex == ringIndex }) {
            var updatedRings = store.rings
            updatedRings[index].locked.toggle()
            store.rings = updatedRings
        }
    }

    func bindingForRing(_ index: Int) -> Binding<Ring>? {
        guard let idx = store.rings.firstIndex(where: { $0.ringIndex == index }) else { return nil }
        return $store.rings[idx]
    }

    func addRing() {
        let nextIndex = (store.rings.map { $0.ringIndex }.max() ?? 0) + 1
        let baseRadius = (store.rings.map { $0.radius }.max() ?? 100) + 80
        var updatedRings = store.rings
        updatedRings.append(Ring(ringIndex: nextIndex, radius: baseRadius, locked: true))
        store.rings = updatedRings
        print("[ArkheionMap] Added ring index=\(nextIndex)")
    }

    func deleteSelectedRing() {
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
    }

    func unlockAllRings() {
        var updatedRings = store.rings
        for index in updatedRings.indices {
            updatedRings[index].locked = false
        }
        store.rings = updatedRings
    }

    func resetCanvas() {
        store.branches.removeAll()
        store.rings.removeAll()
        store.rings.append(Ring(ringIndex: 0, radius: 100, locked: true))
        store.rings.append(Ring(ringIndex: 1, radius: 180, locked: true))
        selectedRingIndex = nil
        selectedBranchID = nil
        editingRing = nil
    }

    func createBranch(at angle: Double) {
        guard let ringIndex = selectedRingIndex else { return }
        var branch = Branch(ringIndex: ringIndex, angle: angle)
        var updatedBranches = store.branches
        updatedBranches.append(branch)
        store.branches = updatedBranches
        selectedBranchID = branch.id
    }

    func createBranchFromToolbar() {
        guard selectedRingIndex != nil else {
            print("[ArkheionMap] Cannot create branch: no ring selected")
            return
        }
        createBranch(at: 0.0)
    }

    func deleteSelectedBranch() {
        guard let id = selectedBranchID else { return }
        var updatedBranches = store.branches
        updatedBranches.removeAll { $0.id == id }
        store.branches = updatedBranches
        selectedBranchID = nil
    }
}
