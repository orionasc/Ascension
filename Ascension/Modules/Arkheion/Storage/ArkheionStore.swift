import Foundation
import SwiftUI

/// Manages in-memory Arkheion map data. Persistence has been stripped so the
/// map always starts in a clean state on launch.
final class ArkheionStore: ObservableObject {
    @Published var rings: [Ring] = []
    @Published var branches: [Branch] = []

    init() {
        // Initialize with the default ring layout every launch
        self.rings = [
            Ring(ringIndex: 0, radius: 180, locked: true),
            Ring(ringIndex: 1, radius: 260, locked: false)
        ]
        self.branches = []
    }

    // MARK: - Persistence Hooks (disabled)
    // The original implementation saved and loaded JSON files from the
    // application's Documents directory. That logic has been removed to keep
    // the canvas ephemeral. Save/load methods are left as stubs for possible
    // future use.

    func load() {
        // Placeholder: persistence removed
    }

    func save() {
        // Placeholder: persistence removed
    }
}
