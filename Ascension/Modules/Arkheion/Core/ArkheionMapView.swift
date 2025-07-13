import SwiftUI

/// Main view presenting the Arkheion map. This rewrite focuses on the base
/// space layer while keeping compatibility with existing data models. Future
/// versions will layer rings, branches and nodes on top of this canvas.
struct ArkheionMapView: View {

    /// Data store handling persistence of rings and branches
    @StateObject var store = ArkheionStore()
    /// Holds the ring currently being edited.
    @State private var editingRing: RingEditTarget?
    /// Ring briefly highlighted after a tap
    @State var highlightedRingIndex: Int?

    /// Currently selected elements for the editor toolbar
    @State var selectedRingIndex: Int?
    @State var selectedBranchID: UUID?
    @State var selectedNodeID: UUID?

    // Multi-selection support
    @State var selectedRingIndices: Set<Int> = []
    @State var selectedBranchIDs: Set<UUID> = []
    @State var selectedNodeIDs: Set<UUID> = []

    // Drag selection rectangle
    @State internal var marqueeStart: CGPoint? = nil
    @State internal var marqueeCurrent: CGPoint? = nil

    // MARK: - Gestures
    @State internal var lastDragLocation: CGPoint? = nil
    @State internal var zoom: CGFloat = 1.0
    @State internal var offset: CGSize = .zero
    @GestureState internal var gestureZoom: CGFloat = 1.0
    @GestureState internal var dragTranslation: CGSize = .zero

    // Grid overlay toggle
    @State private var showGrid = true
    // Hover indicator
    @State private var hoverRingIndex: Int? = nil
    @State private var hoverAngle: Double = 0.0

    // Custom cursor tracking
    @State private var cursorLocation: CGPoint? = nil

    /// Scale factor used to expand the invisible hit area around the map.
    private let interactionScale: CGFloat = 4

    private var marqueeRect: CGRect? {
        guard let start = marqueeStart, let current = marqueeCurrent else { return nil }
        return CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let currentZoom = zoom * gestureZoom

            ZStack {
                BackgroundLayer()

                ZStack {
                    if showGrid {
                        GridOverlayView(size: geo.size, center: center)
                            .blendMode(.overlay)
                    }

                    ZStack {
                        CoreGlowView()
                            .frame(width: 140, height: 140)
                            .position(center)

                        ForEach(store.rings) { ring in
                            RingView(
                                ring: ring,
                                center: center,
                                highlighted: ring.ringIndex == highlightedRingIndex,
                                selected: selectedRingIndices.contains(ring.ringIndex)
                            )
                        }

                        ForEach($store.branches) { $branch in
                            if let ring = store.rings.first(where: { $0.ringIndex == branch.ringIndex }) {
                                BranchView(
                                    branch: $branch,
                                    center: center,
                                    ringRadius: ring.radius,
                                    selectedBranchID: $selectedBranchID,
                                    selectedNodeID: $selectedNodeID,
                                    multiSelected: selectedBranchIDs.contains(branch.id),
                                    selectedNodeIDs: selectedNodeIDs
                                ) {
                                    addNode(to: branch.id)
                                }
                            }
                        }

                        if let index = hoverRingIndex,
                           let ring = store.rings.first(where: { $0.ringIndex == index }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                                .position(
                                    x: center.x + CGFloat(Darwin.cos(hoverAngle)) * ring.radius,
                                    y: center.y + CGFloat(Darwin.sin(hoverAngle)) * ring.radius
                                )
                                .opacity(0.9)
                                .animation(.easeInOut(duration: 0.2), value: hoverRingIndex)
                                .onTapGesture {
                                    highlight(ringIndex: index)
                                    // onRingTapped is reserved for double taps or explicit adds
                                }
                        }
                    }
                }

                .scaleEffect(currentZoom)
                .offset(x: offset.width + dragTranslation.width,
                        y: offset.height + dragTranslation.height)

                // Expanded invisible layer capturing taps and hovers well
                // beyond the visible frame.
                interactionLayer(center: center, geo: geo)

                TapCaptureView(
                    onTap: { handleTap(at: $0, in: geo) },
                    onDoubleTap: { handleDoubleTap(at: $0, in: geo) },
                    onLongPress: { handleLongPress(at: $0, in: geo) }
                )
                .frame(width: geo.size.width * interactionScale,
                       height: geo.size.height * interactionScale)
                .position(center)
                .zIndex(999)

                Rectangle()
                    .fill(Color.clear)
                    .frame(width: geo.size.width * interactionScale,
                           height: geo.size.height * interactionScale)
                    .position(center)
                    .contentShape(Rectangle())
                    .gesture(selectionGesture(in: geo))
                    .overlay(
                        Button(action: clearSelection) { Color.clear }
                            .keyboardShortcut(.escape, modifiers: [])
                    )
                
            }
            .gesture(dragGesture.simultaneously(with: zoomGesture))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .onAppear {
                print("[ArkheionMap] Appeared with \(store.rings.count) rings")
            }
            .onHover { hovering in
                if !hovering { hoverRingIndex = nil }
            }
            .overlay(controlButtons, alignment: .bottomTrailing)
            .overlay(alignment: .top) {
                if let target = editingRing,
                   let binding = bindingForRing(target.ringIndex) {
                    FloatingRingEditorView(
                        ring: binding,
                        progress: progress(for: target.ringIndex),
                        onBack: { editingRing = nil }
                    )
                    .padding(.top, 20)
                }
            }
            .overlay(alignment: .trailing) {
                EditorToolbarView(
                    rings: $store.rings,
                    branches: $store.branches,
                    selectedRingIndex: $selectedRingIndex,
                    selectedBranchID: $selectedBranchID,
                    selectedNodeID: $selectedNodeID,
                    addRing: addRing,
                    unlockAllRings: unlockAllRings,
                    deleteRing: deleteSelectedRing,
                    createBranch: createBranchFromToolbar,
                    addNode: addNodeFromToolbar,
                    deleteBranch: deleteSelectedBranch,
                    deleteNode: deleteSelectedNode,
                    moveNodeUp: moveSelectedNodeUp,
                    moveNodeDown: moveSelectedNodeDown
                )
                .padding(.trailing, 8)
            }
            .overlay(alignment: .topLeading) {
                CursorOverlay(location: $cursorLocation)
            }
            .overlay(alignment: .topLeading) {
                if let rect = marqueeRect {
                    Rectangle()
                        .fill(Color.blue.opacity(0.15))
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Gestures
    var dragGesture: some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                offset.width += value.translation.width
                offset.height += value.translation.height
            }
    }

    var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoom) { value, state, _ in
                state = value
            }
            .onEnded { value in
                zoom *= value
            }
    }

    func selectionGesture(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if marqueeStart == nil { marqueeStart = value.location }
                marqueeCurrent = value.location
            }
            .onEnded { value in
                marqueeCurrent = value.location
                if let start = marqueeStart {
                    performMarqueeSelection(from: start, to: value.location, in: geo)
                }
                marqueeStart = nil
                marqueeCurrent = nil
            }
    }

    /// Expanded gesture capturing taps anywhere within the enlarged interaction layer.
    private func interactionGesture(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let location = value.location
                lastDragLocation = location
                updateHover(at: location, in: geo)
            }
            .onEnded { value in
                let location = value.location
                handleTap(at: location, in: geo)
                updateHover(at: location, in: geo)
            }
    }

    private func doubleTapGesture(in geo: GeometryProxy) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                let location = lastDragLocation ?? .zero
                handleDoubleTap(at: location, in: geo)
            }
    }

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
        selectedRingIndices = selectedRingIndex.map { Set([$0]) } ?? Set<Int>()
        selectedBranchIDs = selectedBranchID.map { Set([$0]) } ?? Set<UUID>()
        selectedNodeIDs = selectedNodeID.map { Set([$0]) } ?? Set<UUID>()
    }

}


// MARK: - Preview

#if DEBUG
struct ArkheionMapView_Previews: PreviewProvider {
    static var previews: some View {
        ArkheionMapView()
    }
}
#endif

