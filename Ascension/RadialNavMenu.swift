import SwiftUI

struct RadialNavMenuItem: Identifiable {
  let id = UUID()
  var icon: String
  var action: () -> Void
}

struct RadialNavMenu: View {
  // Explicitly specify the type for the `safeAreaInsets` environment value
  // so the compiler can resolve the generic parameter on all supported SDKs.
  @Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets
  var items: [RadialNavMenuItem]
  @State private var revealed = false

  var body: some View {
    GeometryReader { geo in
      let radius = min(geo.size.width, geo.size.height) / 5
      ZStack {
        Capsule()
          .fill(.ultraThinMaterial)
          .frame(width: radius * 2 + 60, height: radius + 40)
          .position(
            x: geo.size.width / 2,
            y: safeAreaInsets.top + (radius + 40) / 2
          )
          .opacity(revealed ? 1 : 0)
          .animation(.easeOut(duration: 0.3), value: revealed)

        ForEach(Array(items.enumerated()), id: \.1.id) { index, item in
          let progress = Double(index) / Double(max(items.count - 1, 1))
          let angle = Double.pi * (1 - progress)
          let x = radius * cos(angle)
          let y = radius * sin(angle)

          Button(action: item.action) {
            Image(systemName: item.icon)
              .frame(width: 40, height: 40)
              .background(Circle().fill(Color.white.opacity(0.15)))
              .overlay(
                Circle()
                  .stroke(Color.white.opacity(0.4), lineWidth: 1)
              )
              .foregroundColor(.white)
          }
          .position(
            x: geo.size.width / 2 + x,
            y: safeAreaInsets.top + y
          )
          .scaleEffect(revealed ? 1 : 0.5)
          .opacity(revealed ? 1 : 0)
          .animation(
            .easeOut(duration: 0.4).delay(Double(index) * 0.05),
            value: revealed
          )
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    .contentShape(Rectangle())
    #if os(macOS)
      .onHover { inside in
        withAnimation { revealed = inside }
      }
    #endif
    .onTapGesture {
      withAnimation { revealed.toggle() }
    }
  }
}

#if DEBUG
  struct RadialNavMenu_Previews: PreviewProvider {
    static var previews: some View {
      RadialNavMenu(items: [
        RadialNavMenuItem(icon: "arrowshape.turn.up.left", action: {}),
        RadialNavMenuItem(icon: "sun.max", action: {}),
        RadialNavMenuItem(icon: "shield", action: {}),
      ])
    }
  }
#endif
