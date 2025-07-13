import SwiftUI

/// Main view presenting the Arkheion map. This rewrite focuses on the base
/// space layer while keeping compatibility with existing data models. Future
/// versions will layer rings, branches and nodes on top of this canvas.
struct ArkheionMapView: View {

    /// Data store handling persistence of rings and branches
    @StateObject private var store = ArkheionStore()
    /// Holds the ring currently being edited.
    @State private var editingRing: RingEditTarget?
    /// Ring briefly highlighted after a tap
    @State private var highlightedRingIndex: Int?

    /// Currently selected elements for the editor toolbar
    @State private var selectedRingIndex: Int?
    @State private var selectedBranchID: UUID?
    @State private var selectedNodeID: UUID?

    // Multi-selection support
    @State private var selectedRingIndices: Set<Int> = []
    @State private var selectedBranchIDs: Set<UUID> = []
    @State private var selectedNodeIDs: Set<UUID> = []

    // Drag selection rectangle
    @State private var marqueeStart: CGPoint? = nil
    @State private var marqueeCurrent: CGPoint? = nil

    // MARK: - Gestures
    @State private var lastDragLocation: CGPoint? = nil
    @State private var zoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var gestureZoom: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

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

    /// Transparent overlay extending the interaction bounds far beyond the
    /// visible canvas. This ensures taps on distant rings and branches are
    /// still registered even when they lie outside the default frame.
    private func interactionLayer(center: CGPoint, geo: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: geo.size.width * interactionScale,
                   height: geo.size.height * interactionScale)
            .position(center)
            .contentShape(Rectangle())
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                offset.width += value.translation.width
                offset.height += value.translation.height
            }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoom) { value, state, _ in
                state = value
            }
            .onEnded { value in
                zoom *= value
            }
    }

    private func selectionGesture(in geo: GeometryProxy) -> some Gesture {
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

    /// Converts locations from the oversized interaction layer back to the
    /// local geometry coordinate space used by the hit testing routines.
    private func convert(location: CGPoint, in geo: GeometryProxy) -> CGPoint {
        let size = CGSize(width: geo.size.width * interactionScale,
                          height: geo.size.height * interactionScale)
        let origin = CGPoint(x: geo.size.width / 2 - size.width / 2,
                             y: geo.size.height / 2 - size.height / 2)
        return CGPoint(x: location.x + origin.x, y: location.y + origin.y)
    }

    /// Maps a raw gesture location from ``TapCaptureView`` back to the
    /// underlying canvas space. The capture layer is larger than the visible
    /// canvas and does **not** share the zoom/offset transforms applied to the
    /// rendered map. The conversion therefore consists of:
    /// 1. Translating from the enlarged interaction layer to the local geometry
    ///    space.
    /// 2. Removing the current pan offset.
    /// 3. Unscaling by the active zoom around the canvas center.
    ///
    ///  ````text
    ///  Tap Location -> [interactionScale offset] -> View Space -> [offset] ->
    ///  Panned Space -> [zoom] -> Canvas Space
    ///  ````
    private func mapToCanvasCoordinates(location: CGPoint, in geo: GeometryProxy) -> CGPoint {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let currentZoom = zoom * gestureZoom

        // Step 1: convert from the oversized interaction layer
        let size = CGSize(width: geo.size.width * interactionScale,
                          height: geo.size.height * interactionScale)
        let origin = CGPoint(x: geo.size.width / 2 - size.width / 2,
                             y: geo.size.height / 2 - size.height / 2)
        var point = CGPoint(x: location.x + origin.x, y: location.y + origin.y)

        // Step 2: remove pan offsets
        point.x -= offset.width + dragTranslation.width
        point.y -= offset.height + dragTranslation.height

        // Step 3: undo zoom around the canvas center
        point.x = center.x + (point.x - center.x) / currentZoom
        point.y = center.y + (point.y - center.y) / currentZoom

        return point
    }

    // MARK: - Controls

    private var gridToggleButton: some View {
        Button(action: { showGrid.toggle() }) {
            Image(systemName: showGrid ? "xmark.circle" : "circle.grid.2x2")
                .font(.title2)
                .padding(8)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .padding()
    }

    private var addRingButton: some View {
        Button(action: addRing) {
            Image(systemName: "plus")
                .font(.title2)
                .padding(8)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .padding()
    }

    private var resetButton: some View {
        Button("Reset", action: resetCanvas)
            .font(.title2)
            .padding(8)
            .background(Color.black.opacity(0.4))
            .clipShape(Capsule())
            .buttonStyle(.plain)
            .padding()
    }

    private var controlButtons: some View {
        HStack {
            gridToggleButton
            addRingButton
            resetButton
        }
    }

    // MARK: - Interaction

    private func onRingTapped(ringIndex: Int, angle: Double) {
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

    private func toggleLock(for ringIndex: Int) {
        if let index = store.rings.firstIndex(where: { $0.ringIndex == ringIndex }) {
            var updatedRings = store.rings
            updatedRings[index].locked.toggle()
            store.rings = updatedRings
        }
    }

    private func bindingForRing(_ index: Int) -> Binding<Ring>? {
        guard let idx = store.rings.firstIndex(where: { $0.ringIndex == index }) else { return nil }
        return $store.rings[idx]
    }

    private func addRing() {
        let nextIndex = (store.rings.map { $0.ringIndex }.max() ?? 0) + 1
        let baseRadius = (store.rings.map { $0.radius }.max() ?? 100) + 80
        var updatedRings = store.rings
        updatedRings.append(Ring(ringIndex: nextIndex, radius: baseRadius, locked: true))
        store.rings = updatedRings
        print("[ArkheionMap] Added ring index=\(nextIndex)")
    }

    private func deleteSelectedRing() {
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

    private func addNode(to branchID: UUID) {
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

    private func unlockAllRings() {
        var updatedRings = store.rings
        for index in updatedRings.indices {
            updatedRings[index].locked = false
        }
        store.rings = updatedRings
    }

    private func resetCanvas() {
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

    private func createBranch(at angle: Double) {
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

    private func createBranchFromToolbar() {
        guard selectedRingIndex != nil else {
            print("[ArkheionMap] Cannot create branch: no ring selected")
            return
        }
        createBranch(at: 0.0)
    }

    private func addNodeFromToolbar() {
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

    private func deleteSelectedBranch() {
        guard let id = selectedBranchID else { return }
        var updatedBranches = store.branches
        updatedBranches.removeAll { $0.id == id }
        store.branches = updatedBranches
        selectedBranchID = nil
        selectedNodeID = nil
        syncSelectionSets()
    }

    private func deleteSelectedNode() {
        guard let branchID = selectedBranchID, let nodeID = selectedNodeID else { return }
        guard let bIndex = store.branches.firstIndex(where: { $0.id == branchID }) else { return }
        var updatedBranches = store.branches
        updatedBranches[bIndex].nodes.removeAll { $0.id == nodeID }
        store.branches = updatedBranches
        selectedNodeID = nil
        syncSelectionSets()
    }

    private func moveSelectedNodeUp() {
        guard let branchID = selectedBranchID, let nodeID = selectedNodeID else { return }
        guard let bIndex = store.branches.firstIndex(where: { $0.id == branchID }) else { return }
        guard let nIndex = store.branches[bIndex].nodes.firstIndex(where: { $0.id == nodeID }), nIndex > 0 else { return }
        var updatedBranches = store.branches
        updatedBranches[bIndex].nodes.swapAt(nIndex, nIndex - 1)
        store.branches = updatedBranches
    }

    private func moveSelectedNodeDown() {
        guard let branchID = selectedBranchID, let nodeID = selectedNodeID else { return }
        guard let bIndex = store.branches.firstIndex(where: { $0.id == branchID }) else { return }
        guard let nIndex = store.branches[bIndex].nodes.firstIndex(where: { $0.id == nodeID }), nIndex < store.branches[bIndex].nodes.count - 1 else { return }
        var updatedBranches = store.branches
        updatedBranches[bIndex].nodes.swapAt(nIndex, nIndex + 1)
        store.branches = updatedBranches
    }

    /// Calculates completion progress for a ring based on nodes finished.
    private func progress(for ringIndex: Int) -> Double {
        let ringBranches = store.branches.filter { $0.ringIndex == ringIndex }
        let nodes = ringBranches.flatMap { $0.nodes }
        guard !nodes.isEmpty else { return 0 }
        let completed = nodes.filter { $0.completed }.count
        return Double(completed) / Double(nodes.count)
    }

    private func syncSelectionSets() {
        selectedRingIndices = selectedRingIndex.map { Set([$0]) } ?? []
        selectedBranchIDs = selectedBranchID.map { Set([$0]) } ?? []
        selectedNodeIDs = selectedNodeID.map { Set([$0]) } ?? []
    }

    // MARK: - Tap Handling
    private func handleTap(at location: CGPoint, in geo: GeometryProxy) {
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

    private func handleDoubleTap(at location: CGPoint, in geo: GeometryProxy) {
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

    private func handleLongPress(at location: CGPoint, in geo: GeometryProxy) {
        print("[ArkheionMap] Long press at \(location)")
        guard let index = nearestRing(at: location, in: geo) else { return }
        toggleLock(for: index)
        highlight(ringIndex: index)
    }

    private func nearestRing(at location: CGPoint, in geo: GeometryProxy) -> Int? {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let point = mapToCanvasCoordinates(location: location, in: geo)
        let distance = hypot(point.x - center.x, point.y - center.y)
        return store.rings.min(by: { abs(distance - $0.radius) < abs(distance - $1.radius) })?.ringIndex
    }

    /// Returns the ring index and angle if the location hovers a ring edge
    private func ringHit(at location: CGPoint, in geo: GeometryProxy) -> (Int, Double)? {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let point = mapToCanvasCoordinates(location: location, in: geo)
        let distance = hypot(point.x - center.x, point.y - center.y)
        let angle = atan2(center.y - point.y, point.x - center.x)
        guard let ring = store.rings.min(by: { abs(distance - $0.radius) < abs(distance - $1.radius) }) else { return nil }
        if abs(distance - ring.radius) <= 20 {
            print("[ArkheionMap] ringHit -> index=\(ring.ringIndex) angle=\(angle)")
            return (ring.ringIndex, Double(angle))
        }

        return nil
    }

    private func updateHover(at location: CGPoint, in geo: GeometryProxy) {
        if let (index, angle) = ringHit(at: location, in: geo) {
            hoverRingIndex = index
            hoverAngle = angle
        } else {
            hoverRingIndex = nil
        }
    }

    private func hitNode(at location: CGPoint, in geo: GeometryProxy) -> (branchID: UUID, nodeID: UUID)? {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let point = mapToCanvasCoordinates(location: location, in: geo)

        for branch in store.branches {
            guard let ring = store.rings.first(where: { $0.ringIndex == branch.ringIndex }) else { continue }
            for (idx, node) in branch.nodes.enumerated() {
                let distance = ring.radius + CGFloat(idx + 1) * 60
                    let position = CGPoint(
                        x: center.x + CGFloat(Darwin.cos(branch.angle)) * distance,
                        y: center.y + CGFloat(Darwin.sin(branch.angle)) * distance
                    )
                let hitRadius = node.size.radius + NodeView.hitPadding
                if hypot(point.x - position.x, point.y - position.y) <= hitRadius {
                    print("[ArkheionMap] hitNode -> branch=\(branch.id) node=\(node.id)")
                    return (branch.id, node.id)
                }
            }
        }
        return nil
    }

    private func highlight(ringIndex: Int) {
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

    private func hitBranch(at location: CGPoint, in geo: GeometryProxy) -> UUID? {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let point = mapToCanvasCoordinates(location: location, in: geo)

        for branch in store.branches {
            guard let ring = store.rings.first(where: { $0.ringIndex == branch.ringIndex }) else { continue }
            let origin = CGPoint(
                x: center.x + CGFloat(Darwin.cos(branch.angle)) * ring.radius,
                y: center.y + CGFloat(Darwin.sin(branch.angle)) * ring.radius
            )
            let length = CGFloat(branch.nodes.count) * 60
            let end = CGPoint(
                x: origin.x + CGFloat(Darwin.cos(branch.angle)) * length,
                y: origin.y + CGFloat(Darwin.sin(branch.angle)) * length
            )
            if distance(from: point, toSegment: origin, end: end) <= 20 {
                print("[ArkheionMap] hitBranch -> id=\(branch.id)")
                return branch.id
            }
        }
        return nil
    }

    private func distance(from point: CGPoint, toSegment start: CGPoint, end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy
        if lengthSquared == 0 { return hypot(point.x - start.x, point.y - start.y) }
        var t = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared
        t = max(0, min(1, t))
        let proj = CGPoint(x: start.x + t * dx, y: start.y + t * dy)
        return hypot(point.x - proj.x, point.y - proj.y)
    }

    private func performMarqueeSelection(from start: CGPoint, to end: CGPoint, in geo: GeometryProxy) {
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

    private func clearSelection() {
        selectedRingIndices.removeAll()
        selectedBranchIDs.removeAll()
        selectedNodeIDs.removeAll()
        selectedRingIndex = nil
        selectedBranchID = nil
        selectedNodeID = nil
    }
}

// MARK: - Background Layer

/// Provides the multi-gradient backdrop with a subtle shimmer.
struct BackgroundLayer: View {

    var body: some View {
        GeometryReader { geo in
            let gradient = LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.0, blue: 0.0),
                    Color(red: 11/255, green: 15/255, blue: 12/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            ZStack {
                gradient

                // Glossy shimmer overlay
                RadialGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.15), .clear]),
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height)
                )
                .blendMode(.screen)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Core Glow View

/// Renders the Ascender Core - a pulsing golden orb at the heart of the map.
struct CoreGlowView: View {
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [Color.orange, Color.yellow.opacity(0.6)]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 70
                )
            )
            .shadow(color: Color.orange.opacity(0.8), radius: 30)
            .scaleEffect(pulse ? 1.05 : 0.95)
            .animation(
                .easeInOut(duration: 2).repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear { pulse = true }
            .allowsHitTesting(false)
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

