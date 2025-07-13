import SwiftUI

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
