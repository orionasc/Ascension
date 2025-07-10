import Foundation
import SwiftUI

/// Represents a journey branching from a ring
struct Branch: Identifiable, Codable {
    var id = UUID()
    var ringIndex: Int
    var angle: Double
    var title: String = "New Journey"
    var themes: [NodeAttribute] = []
    var nodes: [Node] = []
}
