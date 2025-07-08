import SwiftUI

/// Main view presenting the Arkheion map. This rewrite focuses on the base
/// space layer while keeping compatibility with existing data models. Future
/// versions will layer rings, branches and nodes on top of this canvas.
struct ArkheionMapView: View {
    @EnvironmentObject private var progressModel: ArkheionProgressModel

    // MARK: - Gestures
    @State private var zoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var gestureZoom: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Grid overlay toggle
    @State private var showGrid = true

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackgroundLayer()

                if showGrid {
                    GridOverlayView()
                        .blendMode(.overlay)
                }

                CoreGlowView()
                    .frame(width: 140, height: 140)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // Placeholder: future ring layers will be inserted here
                // Placeholder: branches and node layers will follow
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .scaleEffect(zoom * gestureZoom)
            .offset(x: offset.width + dragTranslation.width,
                    y: offset.height + dragTranslation.height)
            .gesture(dragGesture.simultaneously(with: zoomGesture))
            .ignoresSafeArea()
            .overlay(gridToggleButton, alignment: .topTrailing)
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
                    endRadius: min(geo.size.width, geo.size.height)
                )
                .blendMode(.screen)
            }
            .ignoresSafeArea()
        }
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

// MARK: - Grid Overlay

/// Draws faint radial and concentric grid lines used for spatial orientation.
struct GridOverlayView: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxRadius = hypot(size.width, size.height) / 2

                // Concentric circles
                let ringCount = 6
                for i in 1...ringCount {
                    let radius = maxRadius * CGFloat(i) / CGFloat(ringCount)
                    var path = Path()
                    path.addEllipse(in: CGRect(x: center.x - radius,
                                               y: center.y - radius,
                                               width: radius * 2,
                                               height: radius * 2))
                    context.stroke(path, with: .color(.white.opacity(0.1)), lineWidth: 0.5)
                }

                // Radial lines
                let segments = 12
                for i in 0..<segments {
                    let angle = Double(i) / Double(segments) * 2 * .pi
                    var path = Path()
                    path.move(to: center)
                    path.addLine(to: CGPoint(x: center.x + cos(angle) * maxRadius,
                                             y: center.y + sin(angle) * maxRadius))
                    context.stroke(path, with: .color(.white.opacity(0.1)), lineWidth: 0.5)
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
            .environmentObject(ArkheionProgressModel())
    }
}
#endif

