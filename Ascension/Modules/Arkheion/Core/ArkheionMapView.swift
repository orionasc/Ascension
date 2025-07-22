import SwiftUI

struct ArkheionMapView: View {
    @StateObject var store = ArkheionStore()

    @State private var selectedRingIndex: Int? = nil
    @State private var selectedBranchID: UUID? = nil
    @State private var selectedNodeID: UUID? = nil

    @State private var zoom: CGFloat = 1.0
    @GestureState private var gestureZoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero

    @State private var showGrid: Bool = true
    @State private var editingRing: RingEditTarget? = nil

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let currentZoom = zoom * gestureZoom
            let currentOffset = CGSize(
                width: offset.width + dragOffset.width,
                height: offset.height + dragOffset.height
            )

            ZStack {
                Color.black.ignoresSafeArea()

                if showGrid {
                    GridOverlayView(size: geo.size, center: center)
                        .blendMode(.overlay)
                }

                CoreGlowView()
                    .frame(width: 140, height: 140)
                    .position(center)

                ForEach(store.rings) { ring in
                    RingView(
                        ring: ring,
                        center: center,
                        highlighted: false,
                        selected: selectedRingIndex == ring.ringIndex
                    )
                    .onTapGesture {
                        select(ring: ring.ringIndex)
                    }
                }

                ForEach(store.branches) { branch in
                    if let ring = store.rings.first(where: { $0.ringIndex == branch.ringIndex }),
                       let binding = bindingForBranch(branch.id) {
                        BranchView(
                            branch: binding,
                            center: center,
                            ringRadius: ring.radius,
                            selectedBranchID: $selectedBranchID,
                            selectedNodeID: $selectedNodeID
                        ) {
                            addNode(to: branch.id)
                        }
                        .onTapGesture {
                            select(branch: branch.id)
                        }
                    }
                }
            }
            .scaleEffect(currentZoom)
            .offset(currentOffset)
            .gesture(panGesture.simultaneously(with: zoomGesture))
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
            .overlay(alignment: .bottomTrailing) {
                HStack {
                    Button(action: { showGrid.toggle() }) {
                        Image(systemName: showGrid ? "xmark.circle" : "circle.grid.2x2")
                            .font(.title2)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Button(action: addRing) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Button("Reset", action: resetCanvas)
                        .font(.title2)
                        .padding(8)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Capsule())
                }
                .padding()
            }

        }
    }

    // MARK: - Gestures
    private var panGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
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

    // MARK: - Selection
    func select(ring index: Int) {
        selectedRingIndex = index
        selectedBranchID = nil
        selectedNodeID = nil
    }

    func select(branch id: UUID) {
        selectedBranchID = id
        selectedRingIndex = nil
        selectedNodeID = nil
    }

    func select(node id: UUID, branch: UUID) {
        selectedNodeID = id
        selectedBranchID = branch
        selectedRingIndex = nil
    }

    // MARK: - Helpers
    func bindingForBranch(_ id: UUID) -> Binding<Branch>? {
        guard let index = store.branches.firstIndex(where: { $0.id == id }) else { return nil }
        return $store.branches[index]
    }

    func bindingForRing(_ index: Int) -> Binding<Ring>? {
        guard let i = store.rings.firstIndex(where: { $0.ringIndex == index }) else { return nil }
        return $store.rings[i]
    }

    func addNode(to branchID: UUID) {
        guard let index = store.branches.firstIndex(where: { $0.id == branchID }) else { return }
        var updated = store.branches
        updated[index].nodes.insert(Node(), at: 0)
        store.branches = updated
    }

    func progress(for ringIndex: Int) -> Double {
        let nodes = store.branches
            .filter { $0.ringIndex == ringIndex }
            .flatMap { $0.nodes }
        guard !nodes.isEmpty else { return 0.0 }
        let completed = nodes.filter { $0.completed }.count
        return Double(completed) / Double(nodes.count)
    }
}
