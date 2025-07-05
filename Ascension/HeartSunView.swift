import SwiftUI

struct HeartSunView: View {
    @State private var animateGlow = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.9))
                .frame(width: 120, height: 120)
                .shadow(color: Color.orange.opacity(0.4), radius: 40)

            Circle()
                .stroke(Color.orange.opacity(0.6), lineWidth: 6)
                .frame(width: 140, height: 140)
                .blur(radius: 2)
                .scaleEffect(animateGlow ? 1.2 : 1.0, anchor: .center)
                .opacity(animateGlow ? 0.0 : 0.4)
                .animation(
                    .easeOut(duration: 3)
                        .repeatForever(autoreverses: true),
                    value: animateGlow
                )
        }
        .onAppear {
            animateGlow = true
        }
    }
}

#Preview {
    HeartSunView()
}
