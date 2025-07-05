import SwiftUI

struct GlowingSunView: View {
    var color: Color = .orange
    var baseSize: CGFloat = 120
    var glowRadius: CGFloat = 40
    var lineWidth: CGFloat = 6
    var animated: Bool = true
    var animationDuration: Double = 3

    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.9))
                .frame(width: baseSize, height: baseSize)
                .shadow(color: color.opacity(0.4), radius: glowRadius)

            Circle()
                .stroke(color.opacity(0.6), lineWidth: lineWidth)
                .frame(width: baseSize * 1.2, height: baseSize * 1.2)
                .blur(radius: 2)
                .scaleEffect(animated ? (pulse ? 1.3 : 1.0) : 1.0)
                .opacity(animated ? (pulse ? 0.0 : 0.4) : 0.4)
        }
        .onAppear {
            guard animated else { return }
            withAnimation(
                .easeOut(duration: animationDuration)
                    .repeatForever(autoreverses: true)
            ) {
                pulse = true
            }
        }
    }
}

#Preview {
    GlowingSunView()
}
