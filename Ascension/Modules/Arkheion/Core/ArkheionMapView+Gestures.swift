import SwiftUI

extension ArkheionMapView {
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
}
