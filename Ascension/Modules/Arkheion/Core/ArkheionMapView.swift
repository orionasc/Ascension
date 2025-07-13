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

}


// MARK: - Preview

#if DEBUG
struct ArkheionMapView_Previews: PreviewProvider {
    static var previews: some View {
        ArkheionMapView()
    }
}
#endif

