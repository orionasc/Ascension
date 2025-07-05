import SwiftUI

struct AscensionHomeView: View {
    struct Module: Identifiable {
        let id = UUID()
        var name: String
        var active: Bool
        var angle: Double
        var systemImage: String
    }

    private let modules: [Module] = [
        Module(name: "Arkheion", active: true, angle: 0, systemImage: "tray.full"),
        Module(name: "Lightborne", active: false, angle: 2 * .pi / 3, systemImage: "sun.max"),
        Module(name: "Vanguard", active: false, angle: 4 * .pi / 3, systemImage: "shield")
    ]

    @State private var showQuote = false

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) * 0.35

            ZStack {
                // 1. Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.26, green: 0.26, blue: 0.28),
                        Color(red: 0.32, green: 0.18, blue: 0.10)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // 3. Orbiting modules
                ForEach(modules) { module in
                    ModuleButtonView(
                        icon: module.systemImage,
                        label: module.name,
                        active: module.active
                    ) {
                        if module.active {
                            print("\(module.name) launched")
                        } else {
                            print("Locked")
                        }
                    }
                    .offset(
                        x: radius * cos(module.angle),
                        y: radius * sin(module.angle)
                    )
                }

                // 2. Heart Sun
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.9))
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.orange.opacity(0.4), radius: 40)

                    Circle()
                        .stroke(Color.orange.opacity(0.6), lineWidth: 6)
                        .frame(width: 140, height: 140)
                        .blur(radius: 2)
                }
                .onTapGesture {
                    print("Arkheion Launched")
                }

                // 4. ARC sigil
                Image(systemName: "a.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .opacity(0.3)
                    .position(x: geo.size.width - 40, y: geo.size.height - 40)
                    .onTapGesture {
                        showQuote.toggle()
                    }

                if showQuote {
                    Text("\u{201c}Reflection is ignition.\u{201d}")
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .transition(.opacity)
                }

                // 5. Header text
                Text("Welcome, Ascendant")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: headerAlignment)
                    .padding([.top, .leading, .trailing], 20)
            }
        }
    }

    private var headerAlignment: Alignment {
#if os(macOS)
        return .topLeading
#else
        return .top
#endif
    }
}

#Preview {
    AscensionHomeView()
}

