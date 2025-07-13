import SwiftUI

extension ArkheionMapView {
    // MARK: - Tap Handling
    func handleTap(at location: CGPoint, in geo: GeometryProxy) {
        print("[ArkheionMap] Tap at \(location)")
        if let hit = hitNode(at: location, in: geo) {
            selectedBranchID = hit.branchID
            selectedNodeID = hit.nodeID
            selectedRingIndex = nil
            print("[ArkheionMap] Selected node: \(hit.nodeID)")
            syncSelectionSets()
            return
        }

        if let branchID = hitBranch(at: location, in: geo) {
            selectedBranchID = branchID
            selectedNodeID = nil
            selectedRingIndex = nil
            print("[ArkheionMap] Selected branch: \(branchID)")
            syncSelectionSets()
            return
        }

        if let (ringIndex, _) = ringHit(at: location, in: geo) {
            highlight(ringIndex: ringIndex)
            selectedRingIndex = ringIndex
            selectedBranchID = nil
            selectedNodeID = nil
            print("[ArkheionMap] Selected ring: \(ringIndex)")
            syncSelectionSets()
            return
        } else {
            selectedRingIndex = nil
            selectedBranchID = nil
            selectedNodeID = nil
            syncSelectionSets()
        }
    }

    func handleDoubleTap(at location: CGPoint, in geo: GeometryProxy) {
        print("[ArkheionMap] Double tap at \(location)")
        guard let ringIndex = nearestRing(at: location, in: geo) else { return }
        highlight(ringIndex: ringIndex)
        selectedRingIndex = ringIndex
        syncSelectionSets()

        // Calculate the angle of the tap relative to the map center
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let point = mapToCanvasCoordinates(location: location, in: geo)
        let angle = atan2(center.y - point.y, point.x - center.x)
        print("[ArkheionMap] Computed angle \(angle)")

        createBranch(at: Double(angle))
    }

    func handleLongPress(at location: CGPoint, in geo: GeometryProxy) {
        print("[ArkheionMap] Long press at \(location)")
        guard let index = nearestRing(at: location, in: geo) else { return }
        toggleLock(for: index)
        highlight(ringIndex: index)
    }

    func highlight(ringIndex: Int) {
#if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
        print("[ArkheionMap] Highlight ring \(ringIndex)")
        highlightedRingIndex = ringIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if highlightedRingIndex == ringIndex {
                highlightedRingIndex = nil
            }
        }
    }

    func performMarqueeSelection(from start: CGPoint, to end: CGPoint, in geo: GeometryProxy) {
        let p1 = mapToCanvasCoordinates(location: start, in: geo)
        let p2 = mapToCanvasCoordinates(location: end, in: geo)
        let rect = CGRect(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p2.x - p1.x),
            height: abs(p2.y - p1.y)
        )

        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

        var ringSet: Set<Int> = []
        var branchSet: Set<UUID> = []
        var nodeSet: Set<UUID> = []

        for ring in store.rings {
            if rect.contains(center) {
                ringSet.insert(ring.ringIndex)
            }
        }

        for branch in store.branches {
            guard let ring = store.rings.first(where: { $0.ringIndex == branch.ringIndex }) else { continue }
            let length = CGFloat(branch.nodes.count) * 60
            let dist = ring.radius + length / 2
            let bCenter = CGPoint(
                x: center.x + CGFloat(Darwin.cos(branch.angle)) * dist,
                y: center.y + CGFloat(Darwin.sin(branch.angle)) * dist
            )
            if rect.contains(bCenter) {
                branchSet.insert(branch.id)
            }
            for (idx, node) in branch.nodes.enumerated() {
                let d = ring.radius + CGFloat(idx + 1) * 60
                let nPos = CGPoint(
                    x: center.x + CGFloat(Darwin.cos(branch.angle)) * d,
                    y: center.y + CGFloat(Darwin.sin(branch.angle)) * d
                )
                if rect.contains(nPos) {
                    nodeSet.insert(node.id)
                }
            }
        }

        selectedRingIndices = ringSet
        selectedBranchIDs = branchSet
        selectedNodeIDs = nodeSet

        selectedRingIndex = ringSet.first
        selectedBranchID = branchSet.first
        selectedNodeID = nodeSet.first
    }

    func clearSelection() {
        selectedRingIndices.removeAll()
        selectedBranchIDs.removeAll()
        selectedNodeIDs.removeAll()
        selectedRingIndex = nil
        selectedBranchID = nil
        selectedNodeID = nil
    }

    func syncSelectionSets() {
        selectedRingIndices = selectedRingIndex.map { Set([$0]) } ?? []
        selectedBranchIDs = selectedBranchID.map { Set([$0]) } ?? []
        selectedNodeIDs = selectedNodeID.map { Set([$0]) } ?? []
    }
}
