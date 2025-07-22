import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Main view presenting the Arkheion map. This rewrite focuses on the base
/// space layer while keeping compatibility with existing data models. Future
/// versions will layer rings, branches and nodes on top of this canvas.
struct ArkheionMapView: View {

    /// Data store handling persistence of rings and branches
    @StateObject var store = ArkheionStore()
    /// Holds the ring currently being edited.
    @State var editingRing: RingEditTarget?
    /// Ring briefly highlighted after a tap
    @State var highlightedRingIndex: Int?

    /// Currently selected elements for the editor toolbar
    @State var selectedRingIndex: Int?
    @State var selectedBranchID: UUID?
    @State var selectedNodeID: UUID?



    // MARK: - Gestures
    @State internal var lastDragLocation: CGPoint? = nil
    @State internal var zoom: CGFloat = 1.0
    @State internal var offset: CGSize = .zero
    @GestureState internal var gestureZoom: CGFloat = 1.0
    @GestureState internal var dragTranslation: CGSize = .zero

    // Tap timing for gesture recognition
    @State private var lastTapTime: Date? = nil
    private let doubleTapThreshold: TimeInterval = 0.3
    private let tapMovementThreshold: CGFloat = 10

    // Grid overlay toggle
    @State var showGrid = true
    // Hover indicator
    @State var hoverRingIndex: Int? = nil
    @State var hoverAngle: Double = 0.0

    // Custom cursor tracking
    @State private var cursorLocation: CGPoint? = nil

    /// Scale factor used to expand the invisible hit area around the map.
    let interactionScale: CGFloat = 4


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
                                selected: selectedRingIndex == ring.ringIndex,
                                onTap: {
                                    highlight(ringIndex: ring.ringIndex)
                                    select(ringIndex: ring.ringIndex)
                                }
                            )
                        }

                        ForEach($store.branches) { $branch in
                            if let ring = store.rings.first(where: { $0.ringIndex == branch.ringIndex }) {
                                BranchView(
                                    branch: $branch,
                                    center: center,
                                    ringRadius: ring.radius,
                                    selectedBranchID: $selectedBranchID,
                                    onTap: {
                                        select(branchID: branch.id)
                                    }
                                )
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

                // Expanded invisible layer capturing hover movement.
                interactionLayer(center: center, geo: geo)
                    .gesture(hoverGesture(in: geo))
                    .onTapGesture {
                        clearSelection()
                    }
                
            }
            .gesture(panGesture.simultaneously(with: zoomGesture))
            .simultaneousGesture(doubleTapGesture(in: geo))
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
                        progress: 0,
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
                    addRing: addRing,
                    unlockAllRings: unlockAllRings,
                    deleteRing: deleteSelectedRing,
                    createBranch: createBranchFromToolbar,
                    deleteBranch: deleteSelectedBranch
                )
                .padding(.trailing, 8)
            }
            .overlay(alignment: .topLeading) {
                CursorOverlay(location: $cursorLocation)
            }
        }
    }

    // MARK: - Gestures
    var panGesture: some Gesture {
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

    /// Tracks pointer movement across the enlarged interaction layer.
    private func hoverGesture(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let location = value.location
                lastDragLocation = location
                updateHover(at: location, in: geo)
            }
            .onEnded { value in
                let location = value.location
                lastDragLocation = location
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

    func handleDoubleTap(at location: CGPoint, in geo: GeometryProxy) {
        print("[ArkheionMap] Double tap at \(location)")
        guard let ringIndex = nearestRing(at: location, in: geo) else { return }
        highlight(ringIndex: ringIndex)
        selectedRingIndex = ringIndex

        // Calculate the angle of the tap relative to the map center
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let point = mapToCanvasCoordinates(location: location, in: geo)
        let angle = atan2(point.y - center.y, point.x - center.x)
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

    // MARK: - Selection Helpers
    func select(nodeID: UUID, branchID: UUID) {
        selectedNodeID = nodeID
        selectedBranchID = branchID
        selectedRingIndex = nil
    }

    func select(branchID: UUID) {
        selectedBranchID = branchID
        selectedRingIndex = nil
        selectedNodeID = nil
    }

    func select(ringIndex: Int) {
        selectedRingIndex = ringIndex
        selectedBranchID = nil
        selectedNodeID = nil
    }

    func clearSelection() {
        if selectedRingIndex != nil || selectedBranchID != nil || selectedNodeID != nil {
            print("[ArkheionMap] Selection cleared.")
        }

        DispatchQueue.main.async {
            selectedRingIndex = nil
            selectedBranchID = nil
            selectedNodeID = nil
        }
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

