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
    @State private var zoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var pinchScale: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero

    // Grid overlay toggle
    @State var showGrid = true


    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let currentZoom = zoom * pinchScale

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

                    }
                }

                .scaleEffect(currentZoom)
                .offset(x: offset.width + dragOffset.width,
                        y: offset.height + dragOffset.height)

                
            }
            .gesture(panGesture.simultaneously(with: zoomGesture))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .onAppear {
                print("[ArkheionMap] Appeared with \(store.rings.count) rings")
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
        }
    }

    // MARK: - Gestures
    var panGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                offset.width += value.translation.width
                offset.height += value.translation.height
            }
    }

    var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($pinchScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                zoom *= value
            }
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

