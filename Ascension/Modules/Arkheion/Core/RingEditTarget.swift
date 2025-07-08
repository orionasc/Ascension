import Foundation

/// Wrapper used when presenting the ring editor via `sheet(item:)`.
/// Stores the ring index and conforms to `Identifiable`.
struct RingEditTarget: Identifiable {
    var ringIndex: Int
    var id: Int { ringIndex }
}
