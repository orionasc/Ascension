import SwiftUI

struct ArkheionPrecisionInputLayer: View {
    var zoom: CGFloat
    var offset: CGSize
    var geo: GeometryProxy
    var rings: [Ring]
    var branches: [Branch]
    var onSelectNode: (UUID, UUID) -> Void
    var onSelectBranch: (UUID) -> Void
    var onSelectRing: (Int) -> Void
    var onClearSelection: () -> Void
    var onCreateBranch: (Double, Int) -> Void

    @State private var lastTapTime: Date? = nil
    private let doubleTapThreshold: TimeInterval = 0.3

    enum SelectionResult {
        case node(branch: UUID, node: UUID)
        case branch(UUID)
        case ring(Int)
        case none
    }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let location = value.location
                        let now = Date()

                        if let lastTime = lastTapTime, now.timeIntervalSince(lastTime) < doubleTapThreshold {
                            handleDoubleTap(location)
                            lastTapTime = nil // prevent triple tap
                        } else {
                            handleTap(location)
                            lastTapTime = now
                        }
                    }
            )

            .simultaneousGesture(
                TapGesture(count: 1)
                    .onEnded { location in
                        let canvasPoint = toCanvasCoords(location)
                        switch resolveHit(at: canvasPoint) {
                        case let .node(branch, node):
                            onSelectNode(branch, node)
                        case let .branch(id):
                            onSelectBranch(id)
                        case let .ring(index):
                            onSelectRing(index)
                        case .none:
                            print("[InputLayer] Clearing selection — no hit detected")
                            onClearSelection()
                        }
                    }
            )

    }

    private func handleTap(_ location: CGPoint) {
        let canvasPoint = toCanvasCoords(location)
        switch resolveHit(at: canvasPoint) {
        case let .node(branch, node):
            onSelectNode(branch, node)
        case let .branch(id):
            onSelectBranch(id)
        case let .ring(index):
            onSelectRing(index)
        case .none:
            print("[InputLayer] Clearing selection — no hit detected")
            onClearSelection()
        }
    }

    private func handleDoubleTap(_ location: CGPoint) {
        let canvasPoint = toCanvasCoords(location)
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let angle = atan2(canvasPoint.y - center.y, canvasPoint.x - center.x)
        guard let ringIndex = nearestRingIndex(to: canvasPoint) else { return }
        onCreateBranch(angle, ringIndex)
    }

    private func toCanvasCoords(_ location: CGPoint) -> CGPoint {
        var point = location
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        point.x -= geo.frame(in: .local).origin.x
        point.y -= geo.frame(in: .local).origin.y
        point.x -= offset.width
        point.y -= offset.height
        point.x = center.x + (point.x - center.x) / zoom
        point.y = center.y + (point.y - center.y) / zoom
        return point
    }

    private func resolveHit(at point: CGPoint) -> SelectionResult {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        for branch in branches {
            guard let ring = rings.first(where: { $0.ringIndex == branch.ringIndex }) else { continue }
            for (i, node) in branch.nodes.enumerated() {
                let distance = ring.radius + CGFloat(i + 1) * 60
                let position = CGPoint(
                    x: center.x + CGFloat(Darwin.cos(branch.angle)) * distance,
                    y: center.y + CGFloat(Darwin.sin(branch.angle)) * distance
                )
                let hitRadius = max(30, node.size.radius + 12)
                if hypot(point.x - position.x, point.y - position.y) < hitRadius {
                    print("[HitTest] Tapped at \(point), checking node at \(position), radius \(hitRadius)")
                    guard !node.id.uuidString.isEmpty else { continue }
                    return .node(branch: branch.id, node: node.id)
                }
            }
        }

        for branch in branches {
            guard let ring = rings.first(where: { $0.ringIndex == branch.ringIndex }) else { continue }
            let origin = CGPoint(
                x: center.x + CGFloat(Darwin.cos(branch.angle)) * ring.radius,
                y: center.y + CGFloat(Darwin.sin(branch.angle)) * ring.radius
            )
            let length = CGFloat(branch.nodes.count) * 60
            let end = CGPoint(
                x: origin.x + CGFloat(Darwin.cos(branch.angle)) * length,
                y: origin.y + CGFloat(Darwin.sin(branch.angle)) * length
            )
            if distance(from: point, toSegment: origin, end: end) < 20 {
                return .branch(branch.id)
            }
        }

        let dist = hypot(point.x - center.x, point.y - center.y)
        if let ring = rings.min(by: { abs(dist - $0.radius) < abs(dist - $1.radius) }), abs(dist - ring.radius) < 25 {
            return .ring(ring.ringIndex)
        }
        print("[HitTest] No node matched for tap at \(point)")
        return .none
    }

    private func nearestRingIndex(to point: CGPoint) -> Int? {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let dist = hypot(point.x - center.x, point.y - center.y)
        return rings.min(by: { abs(dist - $0.radius) < abs(dist - $1.radius) })?.ringIndex
    }

    private func distance(from point: CGPoint, toSegment start: CGPoint, end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy
        if lengthSquared == 0 { return hypot(point.x - start.x, point.y - start.y) }
        var t = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared
        t = max(0, min(1, t))
        let proj = CGPoint(x: start.x + t * dx, y: start.y + t * dy)
        return hypot(point.x - proj.x, point.y - proj.y)
    }
}

