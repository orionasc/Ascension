import SwiftUI

/// Main view presenting the Arkheion map. This rewrite focuses on the base
/// space layer while keeping compatibility with existing data models. Future
/// versions will layer rings, branches and nodes on top of this canvas.
struct ArkheionMapView: View {

    /// Sample ring data. Later this will be loaded from persistent storage.
    @State private var rings: [Ring] = [
        Ring(ringIndex: 0, radius: 180, locked: true),
        Ring(ringIndex: 1, radius: 260, locked: false)
    ]

    @State private var branches: [Branch] = []
    /// Holds the ring currently being edited.
    @State private var editingRing: RingEditTarget?
    /// Ring briefly highlighted after a tap
    @State private var highlightedRingIndex: Int?

    /// Currently selected elements for the editor toolbar
    @State private var selectedRingIndex: Int?
    @State private var selectedBranchID: UUID?
    @State private var selectedNodeID: UUID?

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

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let currentZoom = zoom * gestureZoom

            ZStack {
                BackgroundLayer()

                ZStack {
                    if showGrid {
                        GridOverlayView()
                            .blendMode(.overlay)
                    }

                    ZStack {
                        CoreGlowView()
                            .frame(width: 140, height: 140)
                            .position(center)

                        ForEach(rings) { ring in
                            RingView(
                                ring: ring,
                                center: center,
                                highlighted: ring.ringIndex == highlightedRingIndex
                            )
                        }

                        ForEach($branches) { $branch in
                            if let ring = rings.first(where: { $0.ringIndex == branch.ringIndex }) {
                                BranchView(
                                    branch: $branch,
                                    center: center,
                                    ringRadius: ring.radius,
                                    selectedBranchID: $selectedBranchID,
                                    selectedNodeID: $selectedNodeID
                                ) {
                                    addNode(to: branch.id)
                                }
                            }
                        }

                        if let index = hoverRingIndex,
                           let ring = rings.first(where: { $0.ringIndex == index }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                                .position(
                                    x: center.x + cos(hoverAngle) * ring.radius,
                                    y: center.y + sin(hoverAngle) * ring.radius
                                )
                                .opacity(0.9)
                                .animation(.easeInOut(duration: 0.2), value: hoverRingIndex)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .scaleEffect(currentZoom)
                .offset(x: offset.width + dragTranslation.width,
                        y: offset.height + dragTranslation.height)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            lastDragLocation = value.location
                            updateHover(at: value.location, in: geo)
                        }
                        .onEnded { value in
                            handleTap(at: value.location, in: geo)
                            updateHover(at: value.location, in: geo)
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            let location = lastDragLocation ?? .zero
                            handleDoubleTap(at: location, in: geo)
                        }
                )
                
            }
            .gesture(dragGesture.simultaneously(with: zoomGesture))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .onHover { hovering in
                if !hovering { hoverRingIndex = nil }
            }
            .overlay(gridToggleButton, alignment: .topTrailing)
            .overlay(addRingButton, alignment: .bottomTrailing)
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
                    rings: $rings,
                    branches: $branches,
                    selectedRingIndex: $selectedRingIndex,
                    selectedBranchID: $selectedBranchID,
                    selectedNodeID: $selectedNodeID,
                    addRing: addRing,
                    unlockAllRings: unlockAllRings,
                    deleteRing: deleteSelectedRing,
                    createBranch: createBranch,
                    addNode: addNodeFromToolbar,
                    deleteBranch: deleteSelectedBranch,
                    deleteNode: deleteSelectedNode,
                    moveNodeUp: moveSelectedNodeUp,
                    moveNodeDown: moveSelectedNodeDown
                )
                .padding(.trailing, 8)
            }
        }
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

    // MARK: - Interaction

    private func onRingTapped(ringIndex: Int, angle: Double) {
        selectedRingIndex = ringIndex
        selectedBranchID = nil
        selectedNodeID = nil
        guard let ring = rings.first(where: { $0.ringIndex == ringIndex }), !ring.locked else { return }
        let branch = Branch(ringIndex: ringIndex, angle: angle)
        branches.append(branch)
        selectedBranchID = branch.id
    }

    private func toggleLock(for ringIndex: Int) {
        if let index = rings.firstIndex(where: { $0.ringIndex == ringIndex }) {
            rings[index].locked.toggle()
        }
    }

    private func bindingForRing(_ index: Int) -> Binding<Ring>? {
        guard let idx = rings.firstIndex(where: { $0.ringIndex == index }) else { return nil }
        return $rings[idx]
    }

    private func addRing() {
        let nextIndex = (rings.map { $0.ringIndex }.max() ?? 0) + 1
        let baseRadius = (rings.map { $0.radius }.max() ?? 100) + 80
        rings.append(Ring(ringIndex: nextIndex, radius: baseRadius, locked: true))
    }

    private func deleteSelectedRing() {
        guard let ringIndex = selectedRingIndex else { return }
        guard rings.count > 1 else { return }
        rings.removeAll { $0.ringIndex == ringIndex }
        branches.removeAll { $0.ringIndex == ringIndex }
        if editingRing?.ringIndex == ringIndex { editingRing = nil }
        selectedRingIndex = nil
        selectedBranchID = nil
        selectedNodeID = nil
    }

    private func addNode(to branchID: UUID) {
        guard let index = branches.firstIndex(where: { $0.id == branchID }) else { return }
        let node = Node()
        branches[index].nodes.insert(node, at: 0)
        selectedNodeID = node.id
    }

    private func unlockAllRings() {
        for index in rings.indices {
            rings[index].locked = false
        }
    }

    private func createBranch() {
        guard let ringIndex = selectedRingIndex else { return }
        let branch = Branch(ringIndex: ringIndex, angle: 0)
        branches.append(branch)
        selectedBranchID = branch.id
    }

    private func addNodeFromToolbar() {
        guard let branchID = selectedBranchID else { return }
        addNode(to: branchID)
    }

    private func deleteSelectedBranch() {
        guard let id = selectedBranchID else { return }
        branches.removeAll { $0.id == id }
        selectedBranchID = nil
        selectedNodeID = nil
    }

    private func deleteSelectedNode() {
        guard let branchID = selectedBranchID, let nodeID = selectedNodeID else { return }
        guard let bIndex = branches.firstIndex(where: { $0.id == branchID }) else { return }
        branches[bIndex].nodes.removeAll { $0.id == nodeID }
        selectedNodeID = nil
    }

    private func moveSelectedNodeUp() {
        guard let branchID = selectedBranchID, let nodeID = selectedNodeID else { return }
        guard let bIndex = branches.firstIndex(where: { $0.id == branchID }) else { return }
        guard let nIndex = branches[bIndex].nodes.firstIndex(where: { $0.id == nodeID }), nIndex > 0 else { return }
        branches[bIndex].nodes.swapAt(nIndex, nIndex - 1)
    }

    private func moveSelectedNodeDown() {
        guard let branchID = selectedBranchID, let nodeID = selectedNodeID else { return }
        guard let bIndex = branches.firstIndex(where: { $0.id == branchID }) else { return }
        guard let nIndex = branches[bIndex].nodes.firstIndex(where: { $0.id == nodeID }), nIndex < branches[bIndex].nodes.count - 1 else { return }
        branches[bIndex].nodes.swapAt(nIndex, nIndex + 1)
    }

    /// Calculates completion progress for a ring based on nodes finished.
    private func progress(for ringIndex: Int) -> Double {
        let ringBranches = branches.filter { $0.ringIndex == ringIndex }
        let nodes = ringBranches.flatMap { $0.nodes }
        guard !nodes.isEmpty else { return 0 }
        let completed = nodes.filter { $0.completed }.count
        return Double(completed) / Double(nodes.count)
    }

    // MARK: - Tap Handling
    private func handleTap(at location: CGPoint, in geo: GeometryProxy) {
        if let hit = hitNode(at: location, in: geo) {
            selectedBranchID = hit.branchID
            selectedNodeID = hit.nodeID
            selectedRingIndex = nil
            return
        }

        if let branchID = hitBranch(at: location, in: geo) {
            selectedBranchID = branchID
            selectedNodeID = nil
            selectedRingIndex = nil
            return
        }

        if let (ringIndex, angle) = ringHit(at: location, in: geo) {
            highlight(ringIndex: ringIndex)
            onRingTapped(ringIndex: ringIndex, angle: angle)
        } else {
            selectedRingIndex = nil
            selectedBranchID = nil
            selectedNodeID = nil
        }
    }

    private func handleDoubleTap(at location: CGPoint, in geo: GeometryProxy) {
        guard let ringIndex = nearestRing(at: location, in: geo) else { return }
        highlight(ringIndex: ringIndex)
        editingRing = RingEditTarget(ringIndex: ringIndex)
    }

    private func handleLongPress(at location: CGPoint, in geo: GeometryProxy) {
        guard let index = nearestRing(at: location, in: geo) else { return }
        toggleLock(for: index)
        highlight(ringIndex: index)
    }

    private func nearestRing(at location: CGPoint, in geo: GeometryProxy) -> Int? {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let currentZoom = zoom * gestureZoom
        var point = location
        point.x -= offset.width + dragTranslation.width
        point.y -= offset.height + dragTranslation.height
        point.x = center.x + (point.x - center.x) / currentZoom
        point.y = center.y + (point.y - center.y) / currentZoom
        let distance = hypot(point.x - center.x, point.y - center.y)
        return rings.min(by: { abs(distance - $0.radius) < abs(distance - $1.radius) })?.ringIndex
    }

    /// Returns the ring index and angle if the location hovers a ring edge
    private func ringHit(at location: CGPoint, in geo: GeometryProxy) -> (Int, Double)? {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let currentZoom = zoom * gestureZoom
        var point = location
        point.x -= offset.width + dragTranslation.width
        point.y -= offset.height + dragTranslation.height
        point.x = center.x + (point.x - center.x) / currentZoom
        point.y = center.y + (point.y - center.y) / currentZoom
        let distance = hypot(point.x - center.x, point.y - center.y)
        let angle = atan2(point.y - center.y, point.x - center.x)
        guard let ring = rings.min(by: { abs(distance - $0.radius) < abs(distance - $1.radius) }) else { return nil }
        if abs(distance - ring.radius) <= 20 {
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
        let currentZoom = zoom * gestureZoom
        var point = location
        point.x -= offset.width + dragTranslation.width
        point.y -= offset.height + dragTranslation.height
        point.x = center.x + (point.x - center.x) / currentZoom
        point.y = center.y + (point.y - center.y) / currentZoom

        for branch in branches {
            guard let ring = rings.first(where: { $0.ringIndex == branch.ringIndex }) else { continue }
            for (idx, node) in branch.nodes.enumerated() {
                let distance = ring.radius + CGFloat(idx + 1) * 60
                let position = CGPoint(
                    x: center.x + cos(branch.angle) * distance,
                    y: center.y + sin(branch.angle) * distance
                )
                let hitRadius = node.size.radius + 12
                if hypot(point.x - position.x, point.y - position.y) <= hitRadius {
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
        highlightedRingIndex = ringIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if highlightedRingIndex == ringIndex {
                highlightedRingIndex = nil
            }
        }
    }

    private func hitBranch(at location: CGPoint, in geo: GeometryProxy) -> UUID? {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let currentZoom = zoom * gestureZoom
        var point = location
        point.x -= offset.width + dragTranslation.width
        point.y -= offset.height + dragTranslation.height
        point.x = center.x + (point.x - center.x) / currentZoom
        point.y = center.y + (point.y - center.y) / currentZoom

        for branch in branches {
            guard let ring = rings.first(where: { $0.ringIndex == branch.ringIndex }) else { continue }
            let origin = CGPoint(
                x: center.x + cos(branch.angle) * ring.radius,
                y: center.y + sin(branch.angle) * ring.radius
            )
            let length = CGFloat(branch.nodes.count + 1) * 60
            let end = CGPoint(
                x: origin.x + cos(branch.angle) * length,
                y: origin.y + sin(branch.angle) * length
            )
            if distance(from: point, toSegment: origin, end: end) <= 20 {
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

