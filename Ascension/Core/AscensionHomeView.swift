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
    @State private var showArkheionMap = false

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
                            if module.name == "Arkheion" {
                                showArkheionMap = true
                            } else {
                                print("\(module.name) launched")
                            }
                        } else {
                            print("Locked")
                        }
                    }
                    .offset(
                        x: radius * CGFloat(Darwin.cos(module.angle)),
                        y: radius * CGFloat(Darwin.sin(module.angle))
                    )
                }

                // 2. Heart Sun
                HeartSunView()
                    .onTapGesture {
                        showArkheionMap = true
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
        .mapPresentation(isPresented: $showArkheionMap) {
            NavigationStack {
                ArkheionMapView()
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

#if os(macOS)
extension View {
    @ViewBuilder
    func mapPresentation<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(MacMapPresenter(isPresented: isPresented))
    }
}

private struct MacMapPresenter: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(\.openWindow) private var openWindow

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { show in
                guard show else { return }
                openWindow(id: "ArkheionMap")
                DispatchQueue.main.async { isPresented = false }
            }
    }
}
#else
extension View {
    @ViewBuilder
    func mapPresentation<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        fullScreenCover(isPresented: isPresented, content: content)
    }
}
#endif

