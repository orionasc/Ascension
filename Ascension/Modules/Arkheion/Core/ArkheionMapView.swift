import SwiftUI

/// Main view presenting the Arkheion map. This rewrite focuses on the base
/// space layer while keeping compatibility with existing data models. Future
/// versions will layer rings, branches and nodes on top of this canvas.
struct ArkheionMapView: View {

    /// Sample ring data. Later this will be loaded from persistent storage.
    private let rings: [Ring] = [
        Ring(ringIndex: 0, radius: 180, locked: false),
        Ring(ringIndex: 1, radius: 260, locked: true),
        Ring(ringIndex: 2, radius: 340, locked: true)
    ]

    // MARK: - Gestures
    @State private var zoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var gestureZoom: CGFloat = 1.0
    @GestureState private var dragTranslation: CGSize = .zero

    // Grid overlay toggle
    @State private var showGrid = true

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
                            RingView(ring: ring, center: center) { index in
                                onRingTapped(ringIndex: index)
                            }
                        }

                        // Placeholder: branches and node layers will follow
                    }
                }
                .scaleEffect(currentZoom)
                .offset(x: offset.width + dragTranslation.width,
                        y: offset.height + dragTranslation.height)
            }
            .gesture(dragGesture.simultaneously(with: zoomGesture))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    // MARK: - Interaction

    private func onRingTapped(ringIndex: Int) {
        // Placeholder for branch anchor creation
        print("Ring \(ringIndex) tapped")
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

