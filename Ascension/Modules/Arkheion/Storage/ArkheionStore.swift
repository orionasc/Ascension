import Foundation
import SwiftUI

/// Manages loading and saving Arkheion map data to a local JSON file.
final class ArkheionStore: ObservableObject {
    @Published var rings: [Ring] = [] {
        didSet { save() }
    }
    @Published var branches: [Branch] = [] {
        didSet { save() }
    }

    private let fileURL: URL
    private let version = 1

    init() {
        let manager = FileManager.default
        let dir = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = dir.appendingPathComponent("ArkheionCache.json")
        load()
    }

    /// Wraps the data stored on disk so we can add versioning later.
    private struct CacheData: Codable {
        var version: Int
        var rings: [Ring]
        var branches: [Branch]
    }

    /// Loads cache from disk or initializes default data if missing or corrupt.
    func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(CacheData.self, from: data)
            self.rings = decoded.rings
            self.branches = decoded.branches
        } catch {
            // Initialize defaults if loading fails
            self.rings = [
                Ring(ringIndex: 0, radius: 180, locked: true),
                Ring(ringIndex: 1, radius: 260, locked: false)
            ]
            self.branches = []
            save()
        }
    }

    /// Saves the current rings and branches to disk.
    func save() {
        let cache = CacheData(version: version, rings: rings, branches: branches)
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("ArkheionStore save error: \(error)")
        }
    }
}
