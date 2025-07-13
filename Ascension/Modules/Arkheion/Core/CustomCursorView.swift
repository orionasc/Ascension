#if os(macOS)
import SwiftUI

/// Simple glowing circle used as the in-app cursor
struct CustomCursorView: View {
    var location: CGPoint
    var visible: Bool

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 12, height: 12)
            .shadow(color: Color.white.opacity(0.8), radius: 4)
            .position(location)
            .opacity(visible ? 1 : 0)
            .animation(.linear(duration: 0.05), value: location)
            .allowsHitTesting(false)
    }
}
#endif
