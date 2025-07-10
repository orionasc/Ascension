import Foundation
import SwiftUI

/// Classification for different kinds of nodes that can appear on a branch.
enum NodeType: String, CaseIterable, Identifiable, Codable {
    case milestone, seal, rite, unknown

    var id: String { rawValue }
}

/// Governing attributes for nodes and journeys.
enum NodeAttribute: String, CaseIterable, Identifiable, Codable {
    case scholar, sage, sovereign, luma, praos, astra, clarity, presence, will, unknown

    var id: String { rawValue }

    /// Color coding for each attribute
    var color: Color {
        switch self {
        case .scholar: return .cyan
        case .sage: return .purple
        case .sovereign: return .yellow
        case .luma: return .white
        case .praos: return .pink
        case .astra: return .indigo
        case .clarity: return .blue
        case .presence: return .green
        case .will: return .red
        case .unknown: return .gray
        }
    }
}

/// Possible visual sizes for a node
enum NodeSize: String, CaseIterable, Identifiable, Codable {
    case small, medium, large
    var id: String { rawValue }

    var radius: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        }
    }
}

/// Data model for a single node on a branch
struct Node: Identifiable, Codable {
    var id = UUID()
    var type: NodeType = .milestone
    var title: String = ""
    var description: String = ""
    var attribute: NodeAttribute = .unknown
    var size: NodeSize = .medium
    var completed: Bool = false
}
