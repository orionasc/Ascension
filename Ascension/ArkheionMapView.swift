import SwiftUI

struct ArkheionMapView: View {
    @EnvironmentObject private var progressModel: ArkheionProgressModel
    @Environment(\.dismiss) private var dismiss
    // Explicitly type the `safeAreaInsets` environment value to avoid generic
    // inference issues when compiling on older SDKs.
    @Environment(\.safeAreaInsets) private var safeInsets: EdgeInsets
    @State private var editNode: ArkheionNode?
    @State private var createNodeArchetype: String?
    @State private var selectedArchetype: String = "Scholar"
    @State private var selectedNodeID: UUID?
    @State private var moveMode = false
    @State private var dragOffsets: [UUID: CGSize] = [:]
    @State private var showDeleteConfirm = false

    // Track node positions for connectors
    @State private var nodePositions: [UUID: CGPoint] = [:]

    // Connection drawing state
    @State private var drawingConnection = false
    @State private var connectionStart: (node: UUID, anchor: Int, point: CGPoint)?
    @State private var currentPoint: CGPoint = .zero

    private let archetypes = ["Scholar", "Sage", "Sovereign"]
    @State private var expanded: [String: Bool] = ["Scholar": false, "Sage": false, "Sovereign": false]
    @State private var knownNodeIDs: Set<UUID> = []
    @State private var newlyAddedIDs: Set<UUID> = []

    // Map navigation state
    @State private var dragModeActive = false
    @State private var canvasOffset: CGSize = .zero
    @GestureState private var dragTranslation: CGSize = .zero
    @State private var zoom: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) * 0.35
            let subRadius = radius * 0.6

            let drag = DragGesture()
                .updating($dragTranslation) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    canvasOffset.width += value.translation.width
                    canvasOffset.height += value.translation.height
                }

            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.32, green: 0.18, blue: 0.10),
                        Color(red: 0.26, green: 0.26, blue: 0.28)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ZStack {
                    connectionLines
                    rootNodes(radius: radius, subRadius: subRadius)
                    if drawingConnection, let start = connectionStart {
                        NodeConnector(start: start.point, end: currentPoint)
                            .stroke(Color.white, lineWidth: 2)
                    }
                    HeartSun()
                }
                .scaleEffect(zoom)
                .offset(
                    x: canvasOffset.width + dragTranslation.width,
                    y: canvasOffset.height + dragTranslation.height
                )
                .gesture(dragModeActive ? drag : nil)

                controlPanel

                RadialNavMenu(items: [
                    RadialNavMenuItem(icon: "arrowshape.turn.up.left") {
                        dismiss()
                    },
                    RadialNavMenuItem(icon: "sun.max") {},
                    RadialNavMenuItem(icon: "shield") {}
                ])

                SidebarControls(
                    zoomIn: { zoom = min(zoom + 0.2, 2.5) },
                    zoomOut: { zoom = max(zoom - 0.2, 0.7) },
                    dragMode: dragModeActive,
                    toggleDragMode: { dragModeActive.toggle() }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: dismiss.callAsFunction) {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .sheet(item: $createNodeArchetype) { archetype in
            NodeCreationView(archetype: archetype)
        }
        .sheet(item: $editNode) { node in
            NodeEditView(node: node)
        }
        .alert("Delete this node?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let id = selectedNodeID {
                    progressModel.deleteNode(with: id)
                    selectedNodeID = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: progressModel.nodes) { nodes in
            let ids = Set(nodes.map(\.id))
            let added = ids.subtracting(knownNodeIDs)
            newlyAddedIDs.formUnion(added)
            knownNodeIDs = ids
        }
    }

    @ViewBuilder
    private var connectionLines: some View {
        ForEach(progressModel.connections, id: \.id) { connection in
            if let from = nodePositions[connection.from],
               let to = nodePositions[connection.to] {
                NodeConnector(start: from, end: to)
                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
            }
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private func rootNodes(radius: CGFloat, subRadius: CGFloat) -> some View {
        ForEach(Array(archetypes.enumerated()), id: \.element) { index, archetype in
            rootNodeContent(index: index,
                            archetype: archetype,
                            radius: radius,
                            subRadius: subRadius)
        }
    }

    @ViewBuilder
    private func rootNodeContent(index: Int,
                                 archetype: String,
                                 radius: CGFloat,
                                 subRadius: CGFloat) -> some View {
        let rootAngle = Double(index) / Double(archetypes.count) * 2 * .pi
        let rootPos = CGPoint(x: radius * cos(rootAngle), y: radius * sin(rootAngle))

        RootNodeView(
            archetype: archetype,
            isExpanded: expanded[archetype] ?? false
        ) {
            withAnimation(.spring()) {
                expanded[archetype]?.toggle()
            }
            selectedArchetype = archetype
        }
        .offset(x: rootPos.x, y: rootPos.y)

        if expanded[archetype] ?? false {
            subNodes(for: archetype,
                     rootAngle: rootAngle,
                     rootPos: rootPos,
                     subRadius: subRadius)
        }
    }

    @ViewBuilder
    private func subNodes(for archetype: String,
                          rootAngle: Double,
                          rootPos: CGPoint,
                          subRadius: CGFloat) -> some View {
        let nodes = progressModel.nodes.filter { $0.archetype == archetype }
        ForEach(Array(nodes.enumerated()), id: \.element.id) { subIndex, node in
            let arcRange = Double.pi / 2
            let startAngle = rootAngle - arcRange / 2
            let angle = startAngle + arcRange * Double(subIndex) / Double(max(nodes.count - 1, 1))
            let baseX = rootPos.x + subRadius * cos(angle)
            let baseY = rootPos.y + subRadius * sin(angle)
            let drag = dragOffsets[node.id] ?? .zero
            let finalX = baseX + node.offset.width + drag.width
            let finalY = baseY + node.offset.height + drag.height
            let _ = updatePosition(for: node.id,
                                               point: CGPoint(x: finalX, y: finalY))

            NodeConnector(start: rootPos, end: CGPoint(x: finalX, y: finalY))
                .stroke(Color.white.opacity(0.3), lineWidth: 1)

            let isNew = newlyAddedIDs.contains(node.id)
            let isSelected = selectedNodeID == node.id
            let delay = Double(subIndex) * 0.05

            NodeView(
                node: node,
                isNew: isNew,
                isSelected: isSelected,
                isMovable: moveMode,
                appearDelay: delay,
                onTap: { selectedNodeID = node.id },
                onEdit: { editNode = node },
                onDelete: { progressModel.deleteNode(with: node.id) },
                onDrag: { dragOffsets[node.id] = $0 },
                onDragEnd: { translation in
                    let newOffset = CGSize(
                        width: node.offset.width + translation.width,
                        height: node.offset.height + translation.height
                    )
                    progressModel.updateNodeOffset(id: node.id, offset: newOffset)
                    dragOffsets[node.id] = .zero
                },
                onAppearDone: { newlyAddedIDs.remove(node.id) }
            )
            .offset(x: finalX, y: finalY)
            .overlay(
                NodeConnectorView(
                    nodeID: node.id,
                    center: CGPoint(x: finalX, y: finalY),
                    editMode: moveMode,
                    onStart: startConnection,
                    onDrag: updateConnection,
                    onEnd: endConnection
                )
                .frame(width: 70, height: 70)
                .offset(x: finalX, y: finalY)
            )
        }
    }

    private var controlPanel: some View {
        VStack(spacing: 12) {
            Button(action: { createNodeArchetype = selectedArchetype }) {
                Image(systemName: "plus")
                    .font(.title2)
            }
            .buttonStyle(.plain)

            if let _ = selectedNodeID {
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.title2)
                }
            }

            Button(action: { moveMode.toggle() }) {
                Image(systemName: "pencil")
                    .font(.title2)
                    .foregroundColor(moveMode ? .yellow : .primary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding()
        .transition(.opacity)
    }
    private func updatePosition(for id: UUID, point: CGPoint) {
        DispatchQueue.main.async {
            nodePositions[id] = point
        }
    }
    // MARK: - Connection Handling

    private func startConnection(id: UUID, anchor: Int, point: CGPoint) {
        drawingConnection = true
        connectionStart = (node: id, anchor: anchor, point: point)
        currentPoint = point
    }

    private func updateConnection(_ point: CGPoint) {
        currentPoint = point
    }

    private func endConnection(id: UUID, anchor: Int, _ point: CGPoint) {
        drawingConnection = false
        if let start = connectionStart, start.node != id {
            progressModel.addConnection(from: start.node, to: id)
        }
        connectionStart = nil
    }
}

private struct NodeView: View {
    var node: ArkheionNode
    var isNew: Bool = false
    var isSelected: Bool = false
    var isMovable: Bool = false
    var appearDelay: Double = 0
    var onTap: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onDrag: (CGSize) -> Void = { _ in }
    var onDragEnd: (CGSize) -> Void = { _ in }
    var onAppearDone: () -> Void = {}

    @State private var pressed = false
    @State private var hovering = false
    @State private var appeared = false
    @State private var highlight = false
    @State private var show = false
    @GestureState private var drag: CGSize = .zero

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 4) {
                circle
                Text(node.title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
#if os(macOS)
        .onHover { hovering = $0 }
#endif
        .offset(drag)
        .gesture(
            isMovable ? DragGesture()
                .updating($drag) { value, state, _ in
                    state = value.translation
                    onDrag(value.translation)
                }
                .onEnded { value in
                    onDragEnd(value.translation)
                }
            : nil
        )
        .onAppear {
            guard !appeared else { return }
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + appearDelay) {
                withAnimation(.spring()) { show = true }
                if isNew {
                    highlight = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        highlight = false
                    }
                }
                onAppearDone()
            }
        }
        .animation(.easeOut(duration: 0.7), value: highlight)
        .nodeContextMenu(onEdit: onEdit, onDelete: onDelete)
    }

    private func handleTap() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            pressed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            pressed = false
        }
        onTap()
    }

    private var circle: some View {
        Circle()
            .fill(nodeColor.opacity(0.8))
            .frame(width: 70, height: 70)
            .overlay(
                Circle()
                    .stroke(nodeColor, lineWidth: 4)
                    .shadow(color: nodeColor.opacity(0.6), radius: 6)
            )
            .overlay(highlightCircle)
            .overlay(selectionCircle)
            .overlay(movableCircle)
            .scaleEffect(show ? (pressed || hovering ? 1.1 : 1) : 0.3)
            .opacity(show ? 1 : 0)
    }

    private var highlightCircle: some View {
        Circle()
            .stroke(nodeColor, lineWidth: 6)
            .scaleEffect(highlight ? 1.4 : 1.2)
            .opacity(highlight ? 0.8 : 0)
    }

    private var selectionCircle: some View {
        Circle()
            .stroke(Color.yellow, lineWidth: 4)
            .scaleEffect(1.4)
            .opacity(isSelected ? 1 : 0)
            .shadow(
                color: Color.yellow.opacity(isSelected ? 0.8 : 0),
                radius: isSelected ? 6 : 0
            )
    }

    private var movableCircle: some View {
        Circle()
            .stroke(nodeColor.opacity(isMovable ? 0.5 : 0), lineWidth: 3)
            .blur(radius: isMovable ? 4 : 0)
    }

    private var nodeColor: Color {
        switch node.archetype {
        case "Scholar": return .blue
        case "Sage": return Color(red: 0.83, green: 0.67, blue: 0.22)
        case "Sovereign": return Color(red: 0.80, green: 0.34, blue: 0.08)
        default: return .accentColor
        }
    }
}

private struct RootNodeView: View {
    var archetype: String
    var isExpanded: Bool
    var action: () -> Void

    private var color: Color {
        switch archetype {
        case "Scholar": return .blue
        case "Sage": return Color(red: 0.83, green: 0.67, blue: 0.22)
        case "Sovereign": return Color(red: 0.80, green: 0.34, blue: 0.08)
        default: return .accentColor
        }
    }

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color.opacity(0.8))
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: isExpanded ? 6 : 4)
                        .shadow(color: color.opacity(0.6), radius: isExpanded ? 8 : 6)
                )
                .overlay(
                    Text(String(archetype.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct HeartSun: View {
    var body: some View {
        GlowingSunView(animated: false)
    }
}

#Preview {
    ArkheionMapView()
        .environmentObject(ArkheionProgressModel())
}
