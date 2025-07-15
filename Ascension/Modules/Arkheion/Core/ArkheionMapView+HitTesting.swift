import SwiftUI

/// Constants controlling hit test tolerance around map elements.
private let branchHitTolerance: CGFloat = 20
private let ringHitTolerance: CGFloat = 25

extension ArkheionMapView {
    // MARK: - Coordinate Mapping
    private func convert(location: CGPoint, in geo: GeometryProxy) -> CGPoint {
        let size = CGSize(width: geo.size.width * interactionScale,
                          height: geo.size.height * interactionScale)
        let origin = CGPoint(x: geo.size.width / 2 - size.width / 2,
                             y: geo.size.height / 2 - size.height / 2)
        return CGPoint(x: location.x + origin.x, y: location.y + origin.y)
    }

    /// Maps a raw gesture location from ``TapCaptureView`` back to the
    /// underlying canvas space.
    func mapToCanvasCoordinates(location: CGPoint, in geo: GeometryProxy) -> CGPoint {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let currentZoom = zoom * gestureZoom

        // Step 1: convert from the oversized interaction layer
        let size = CGSize(width: geo.size.width * interactionScale,
                          height: geo.size.height * interactionScale)
        let origin = CGPoint(x: geo.size.width / 2 - size.width / 2,
                             y: geo.size.height / 2 - size.height / 2)
        var point = CGPoint(x: location.x + origin.x, y: location.y + origin.y)

        // Step 2: remove pan offsets
        point.x -= offset.width + dragTranslation.width
        point.y -= offset.height + dragTranslation.height

        // Step 3: undo zoom around the canvas center
        point.x = center.x + (point.x - center.x) / currentZoom
        point.y = center.y + (point.y - center.y) / currentZoom

        return point
    }

    func nearestRing(at location: CGPoint, in geo: GeometryProxy) -> Int? {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let point = mapToCanvasCoordinates(location: location, in: geo)
        let distance = hypot(point.x - center.x, point.y - center.y)
        return store.rings.min(by: { abs(distance - $0.radius) < abs(distance - $1.radius) })?.ringIndex
    }

    /// Returns the ring index and angle if the location hovers a ring edge
    func ringHit(at location: CGPoint, in geo: GeometryProxy) -> (Int, Double)? {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let point = mapToCanvasCoordinates(location: location, in: geo)
        let distance = hypot(point.x - center.x, point.y - center.y)
        let angle = atan2(point.y - center.y, point.x - center.x)
        guard let ring = store.rings.min(by: { abs(distance - $0.radius) < abs(distance - $1.radius) }) else { return nil }
        if abs(distance - ring.radius) <= ringHitTolerance {
            print("[ArkheionMap] ringHit -> index=\(ring.ringIndex) angle=\(angle)")
            return (ring.ringIndex, Double(angle))
        }

        return nil
    }

    func updateHover(at location: CGPoint, in geo: GeometryProxy) {
        if let (index, angle) = ringHit(at: location, in: geo) {
            hoverRingIndex = index
            hoverAngle = angle
        } else {
            hoverRingIndex = nil
        }
    }

    func hitBranch(at location: CGPoint, in geo: GeometryProxy) -> UUID? {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        let point = mapToCanvasCoordinates(location: location, in: geo)

        for branch in store.branches {
            guard let ring = store.rings.first(where: { $0.ringIndex == branch.ringIndex }) else { continue }
            let origin = CGPoint(
                x: center.x + CGFloat(Darwin.cos(branch.angle)) * ring.radius,
                y: center.y + CGFloat(Darwin.sin(branch.angle)) * ring.radius
            )
            let length = CGFloat(branch.nodes.count) * 60
            let end = CGPoint(
                x: origin.x + CGFloat(Darwin.cos(branch.angle)) * length,
                y: origin.y + CGFloat(Darwin.sin(branch.angle)) * length
            )
            if distance(from: point, toSegment: origin, end: end) <= branchHitTolerance {
                print("[ArkheionMap] hitBranch -> id=\(branch.id)")
                return branch.id
            }
        }
        return nil
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
