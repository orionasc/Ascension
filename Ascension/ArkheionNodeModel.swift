import Foundation
import SwiftUI

enum ArkheionNodeStatus: String, Codable, CaseIterable {
    case dormant = "Dormant"
    case awakening = "Awakening"
    case catalyst = "Catalyst"
    case engraved = "Engraved"
}

enum ArkheionNodeType: String, Codable, CaseIterable {
    case skill = "Skill"
    case threshold = "Threshold"
    case milestone = "Milestone"
    case mystery = "Mystery"
}

struct ArkheionNode: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var archetype: String
    var type: ArkheionNodeType
    var prompt: String
    var quote: String?
    var status: ArkheionNodeStatus

    init(id: UUID = UUID(), title: String, archetype: String, type: ArkheionNodeType, prompt: String, quote: String? = nil, status: ArkheionNodeStatus = .dormant) {
        self.id = id
        self.title = title
        self.archetype = archetype
        self.type = type
        self.prompt = prompt
        self.quote = quote
        self.status = status
    }
}

@MainActor
final class ArkheionProgressModel: ObservableObject {
    @Published private(set) var nodes: [ArkheionNode] = []

    private let fileURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        fileURL = Self.makeFileURL()
        Task {
            await load()
        }
    }

    private static func makeFileURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("arkheion_nodes.json")
    }

    func load() async {
        let fm = FileManager.default
        if fm.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoded = try decoder.decode([ArkheionNode].self, from: data)
                self.nodes = decoded
            } catch {
                print("Failed to load nodes: \(error)")
                self.nodes = []
            }
        } else {
            nodes = Self.defaultNodes()
            await save()
        }
    }

    func addNode(_ node: ArkheionNode) {
        nodes.append(node)
        Task { await save() }
    }

    func updateNode(_ node: ArkheionNode) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
            Task { await save() }
        }
    }

    func deleteNode(with id: UUID) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            nodes.remove(at: index)
            Task { await save() }
        }
    }

    func save() async {
        do {
            let data = try encoder.encode(nodes)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save nodes: \(error)")
        }
    }

    private static func defaultNodes() -> [ArkheionNode] {
        return [
            ArkheionNode(title: "Foundation", archetype: "Scholar", type: .skill, prompt: "Reflect on your knowledge and commit to daily study."),
            ArkheionNode(title: "Insight", archetype: "Sage", type: .threshold, prompt: "Meditate on the nature of wisdom for fifteen minutes."),
            ArkheionNode(title: "Resolve", archetype: "Sovereign", type: .milestone, prompt: "Identify a goal that requires courage and declare it.")
        ]
    }
}

