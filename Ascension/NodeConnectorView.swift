import SwiftUI

/// Displays connection anchor points around a node when edit mode is enabled.
/// Each anchor can begin a connection drag to another node.
struct NodeConnectorView: View {
    var nodeID: UUID
    var center: CGPoint
    var editMode: Bool
    var onStart: (UUID, Int, CGPoint) -> Void = { _,_,_ in }
    var onDrag: (CGPoint) -> Void = { _ in }
    var onEnd: (UUID, Int, CGPoint) -> Void = { _,_,_ in }

    @State private var showAnchors = false
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let radius = min(size.width, size.height) / 2
            let centerLocal = CGPoint(x: size.width / 2, y: size.height / 2)

            ForEach(0..<8, id: .self) { index in
                let angle = Double(index) * .pi / 4
                let offset = CGSize(width: radius * cos(angle),
                                    height: radius * sin(angle))
                let startPoint = CGPoint(x: center.x + offset.width,
                                         y: center.y + offset.height)

                Circle()
                    .fill(Color.white)
                    .frame(width: 15, height: 15)
                    .position(x: centerLocal.x + offset.width,
                              y: centerLocal.y + offset.height)
                    .opacity(showAnchors && editMode ? 1 : 0)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    onStart(nodeID, index, startPoint)
                                }
                                let current = CGPoint(x: startPoint.x + value.translation.width,
                                                      y: startPoint.y + value.translation.height)
                                onDrag(current)
                            }
                            .onEnded { value in
                                isDragging = false
                                let endPoint = CGPoint(x: startPoint.x + value.translation.width,
                                                       y: startPoint.y + value.translation.height)
                                onEnd(nodeID, index, endPoint)
                            }
                    )
            }
        }
#if os(macOS)
        .onHover { hovering in
            if editMode { showAnchors = hovering }
        }
#else
        .onTapGesture {
            if editMode { showAnchors.toggle() }
        }
#endif
    }
}
