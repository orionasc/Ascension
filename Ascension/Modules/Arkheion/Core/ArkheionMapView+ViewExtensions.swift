import SwiftUI

extension ArkheionMapView {
    /// Transparent overlay extending the interaction bounds far beyond the
    /// visible canvas. This ensures taps on distant rings and branches are
    /// still registered even when they lie outside the default frame.
    fileprivate func interactionLayer(center: CGPoint, geo: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: geo.size.width * interactionScale,
                   height: geo.size.height * interactionScale)
            .position(center)
            .contentShape(Rectangle())
    }

    // MARK: - Controls
    fileprivate var gridToggleButton: some View {
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

    fileprivate var addRingButton: some View {
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

    fileprivate var resetButton: some View {
        Button("Reset", action: resetCanvas)
            .font(.title2)
            .padding(8)
            .background(Color.black.opacity(0.4))
            .clipShape(Capsule())
            .buttonStyle(.plain)
            .padding()
    }

    fileprivate var controlButtons: some View {
        HStack {
            gridToggleButton
            addRingButton
            resetButton
        }
    }
}
