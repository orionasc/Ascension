import SwiftUI

struct ArkheionPrecisionInputLayer: View {
    var zoom: CGFloat
    var offset: CGSize
    var geo: GeometryProxy
    var rings: [Ring]
    var branches: [Branch]
    var onSelectBranch: (UUID) -> Void
    var onSelectRing: (Int) -> Void
    var onClearSelection: () -> Void
    var onCreateBranch: (Double, Int) -> Void

    @State private var lastTapTime: Date? = nil
    private let doubleTapThreshold: TimeInterval = 0.3
    private let tapMovementThreshold: CGFloat = 10

    enum SelectionResult {
        case branch(UUID)
        case ring(Int)
        case none
    }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .allowsHitTesting(true)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        let movement = sqrt(dx * dx + dy * dy)
                        guard movement < tapMovementThreshold else { return }

                        let location = value.location
                        let canvasPoint = toCanvasCoords(location)
                        let isNode = nodeHitCheck(at: canvasPoint)

                        let now = Date()
                        if let last = lastTapTime,
                           now.timeIntervalSince(last) < doubleTapThreshold {
                            lastTapTime = nil
                            if isNode {
                                print("[InputLayer] Ignoring double tap — node was hit")
                            } else {
                                handleDoubleTap(location)
                            }
                        } else {
                            handleTap(location)
                            lastTapTime = now
                        }
                    }
            )
    }

    private func handleTap(_ location: CGPoint) {
        let canvasPoint = toCanvasCoords(location)
        switch resolveHit(at: canvasPoint) {
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
        guard let ringIndex = nearestRingIndex(to: canvasPoint) else { return }
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let angle = atan2(canvasPoint.y - center.y, canvasPoint.x - center.x)
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

        // Branches
        for branch in branches {
            guard let ring = rings.first(where: { $0.ringIndex == branch.ringIndex }) else { continue }
            let origin = CGPoint(
                x: center.x + Darwin.cos(branch.angle) * ring.radius,
                y: center.y + Darwin.sin(branch.angle) * ring.radius
            )
            let length = CGFloat(branch.nodes.count) * 60
            let end = CGPoint(
                x: origin.x + Darwin.cos(branch.angle) * length,
                y: origin.y + Darwin.sin(branch.angle) * length
            )
            if distance(from: point, toSegment: origin, end: end) < 20 {
                return .branch(branch.id)
            }
        }

        // Rings
        let dist = hypot(point.x - center.x, point.y - center.y)
        if let ring = rings.min(by: { abs(dist - $0.radius) < abs(dist - $1.radius) }),
           abs(dist - ring.radius) < 25 {
            return .ring(ring.ringIndex)
        }

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
        let lengthSq = dx * dx + dy * dy
        if lengthSq == 0 {
            return hypot(point.x - start.x, point.y - start.y)
        }
        var t = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSq
        t = max(0, min(1, t))
        let proj = CGPoint(x: start.x + t * dx, y: start.y + t * dy)
        return hypot(point.x - proj.x, point.y - proj.y)
    }

    private func nodeHitCheck(at point: CGPoint) -> Bool {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        for branch in branches {
            guard let ring = rings.first(where: { $0.ringIndex == branch.ringIndex }) else { continue }
            let direction = CGPoint(x: cos(branch.angle), y: sin(branch.angle))
            for (i, node) in branch.nodes.enumerated() {
                let distance = ring.radius + CGFloat(i + 1) * 60
                let nodePos = CGPoint(
                    x: center.x + direction.x * distance,
                    y: center.y + direction.y * distance
                )
                let radius = max(node.size.radius, 12) + 10
                if hypot(point.x - nodePos.x, point.y - nodePos.y) <= radius {
                    return true
                }
            }
        }
        return false
    }
}
