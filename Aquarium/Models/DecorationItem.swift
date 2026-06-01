import Foundation
import SwiftUI

enum DecorationCategory: String, CaseIterable, Codable, Identifiable {
    case plants      = "Plants"
    case hardscape   = "Hardscape"
    case structures  = "Structures"
    case substrate   = "Substrate Decor"
    case novelty     = "Novelty"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .plants:    return "leaf.fill"
        case .hardscape: return "mountain.2.fill"
        case .structures: return "building.columns.fill"
        case .substrate: return "circle.hexagongrid.fill"
        case .novelty:   return "star.fill"
        }
    }
}

struct DecorationItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: DecorationCategory
    let emoji: String

    // Scale range for size randomization
    let minScale: Float
    let maxScale: Float

    // Rough footprint in meters (width, height, depth) at scale 1
    let footprint: SIMD3<Float>

    // Which themes this decor looks best in (empty = all)
    let compatibleThemes: [TankTheme]

    // Color tint applied to the placeholder mesh
    let primaryColor: CodableColor
    let secondaryColor: CodableColor
}

// MARK: - Decoration Catalog
extension DecorationItem {
    static let catalog: [DecorationItem] = [
        // PLANTS
        .init(id: "amazon_sword", name: "Amazon Sword", description: "Broad, lush green leaves that sway gently in current.", category: .plants, emoji: "🌿",
              minScale: 0.8, maxScale: 1.4, footprint: SIMD3(0.05, 0.15, 0.05), compatibleThemes: [.tropical],
              primaryColor: CodableColor(0.20, 0.65, 0.20), secondaryColor: CodableColor(0.15, 0.50, 0.15)),
        .init(id: "java_fern", name: "Java Fern", description: "Hardy, dark-green fern that thrives attached to rocks.", category: .plants, emoji: "🌱",
              minScale: 0.7, maxScale: 1.2, footprint: SIMD3(0.04, 0.10, 0.04), compatibleThemes: [.tropical, .coldwater],
              primaryColor: CodableColor(0.15, 0.50, 0.15), secondaryColor: CodableColor(0.10, 0.38, 0.10)),
        .init(id: "vallisneria", name: "Vallisneria", description: "Tall, ribbon-like grass that moves gracefully in the water flow.", category: .plants, emoji: "🎋",
              minScale: 0.9, maxScale: 1.6, footprint: SIMD3(0.02, 0.20, 0.02), compatibleThemes: [.tropical, .coldwater, .zen],
              primaryColor: CodableColor(0.25, 0.70, 0.25), secondaryColor: CodableColor(0.20, 0.55, 0.20)),
        .init(id: "moss_ball", name: "Moss Ball", description: "Perfectly round algae ball. Iconic in Japanese aquariums.", category: .plants, emoji: "🟢",
              minScale: 0.6, maxScale: 1.0, footprint: SIMD3(0.06, 0.06, 0.06), compatibleThemes: [.zen, .coldwater],
              primaryColor: CodableColor(0.20, 0.55, 0.18), secondaryColor: CodableColor(0.15, 0.42, 0.12)),
        .init(id: "sea_anemone", name: "Sea Anemone", description: "Flowing tentacled anemone — perfect home for clownfish.", category: .plants, emoji: "🌸",
              minScale: 0.8, maxScale: 1.3, footprint: SIMD3(0.08, 0.10, 0.08), compatibleThemes: [.saltwater],
              primaryColor: CodableColor(0.85, 0.45, 0.55), secondaryColor: CodableColor(0.70, 0.30, 0.40)),
        .init(id: "coral_brain", name: "Brain Coral", description: "Massive boulder coral with intricate maze-like ridges.", category: .plants, emoji: "🪸",
              minScale: 0.7, maxScale: 1.5, footprint: SIMD3(0.10, 0.08, 0.10), compatibleThemes: [.saltwater],
              primaryColor: CodableColor(0.75, 0.55, 0.35), secondaryColor: CodableColor(0.60, 0.40, 0.22)),
        // HARDSCAPE
        .init(id: "river_stone", name: "River Stone", description: "Smooth, rounded stone worn by centuries of water flow.", category: .hardscape, emoji: "🪨",
              minScale: 0.5, maxScale: 2.0, footprint: SIMD3(0.08, 0.06, 0.07), compatibleThemes: [],
              primaryColor: CodableColor(0.55, 0.52, 0.48), secondaryColor: CodableColor(0.42, 0.38, 0.35)),
        .init(id: "dragon_stone", name: "Dragon Stone", description: "Porous, angular volcanic rock with caves and texture.", category: .hardscape, emoji: "🗿",
              minScale: 0.6, maxScale: 1.8, footprint: SIMD3(0.10, 0.12, 0.09), compatibleThemes: [.tropical, .zen],
              primaryColor: CodableColor(0.42, 0.38, 0.32), secondaryColor: CodableColor(0.30, 0.27, 0.22)),
        .init(id: "driftwood_branch", name: "Driftwood", description: "Twisted, bleached driftwood that anchors the hardscape.", category: .hardscape, emoji: "🪵",
              minScale: 0.7, maxScale: 1.5, footprint: SIMD3(0.18, 0.08, 0.06), compatibleThemes: [.tropical, .coldwater],
              primaryColor: CodableColor(0.52, 0.40, 0.28), secondaryColor: CodableColor(0.38, 0.28, 0.18)),
        .init(id: "slate_stack", name: "Slate Formation", description: "Layered flat slate slabs arranged into dramatic cliffs.", category: .hardscape, emoji: "🏔️",
              minScale: 0.6, maxScale: 1.4, footprint: SIMD3(0.12, 0.14, 0.06), compatibleThemes: [.coldwater, .zen],
              primaryColor: CodableColor(0.35, 0.35, 0.38), secondaryColor: CodableColor(0.25, 0.25, 0.28)),
        // STRUCTURES
        .init(id: "sunken_ship", name: "Sunken Galleon", description: "A weathered wooden sailing ship resting on the seafloor.", category: .structures, emoji: "⚓",
              minScale: 0.8, maxScale: 1.2, footprint: SIMD3(0.20, 0.14, 0.10), compatibleThemes: [.saltwater, .tropical],
              primaryColor: CodableColor(0.45, 0.32, 0.20), secondaryColor: CodableColor(0.30, 0.20, 0.12)),
        .init(id: "roman_ruins", name: "Roman Ruins", description: "Crumbling pillars and archways from a sunken civilization.", category: .structures, emoji: "🏛️",
              minScale: 0.7, maxScale: 1.3, footprint: SIMD3(0.14, 0.16, 0.10), compatibleThemes: [.tropical, .saltwater],
              primaryColor: CodableColor(0.80, 0.75, 0.65), secondaryColor: CodableColor(0.65, 0.60, 0.50)),
        .init(id: "tori_gate", name: "Torii Gate", description: "A classic Japanese shrine gate, guardian of the zen garden.", category: .structures, emoji: "⛩️",
              minScale: 0.6, maxScale: 1.0, footprint: SIMD3(0.08, 0.14, 0.04), compatibleThemes: [.zen],
              primaryColor: CodableColor(0.85, 0.20, 0.10), secondaryColor: CodableColor(0.70, 0.12, 0.06)),
        .init(id: "castle_tower", name: "Castle Tower", description: "A stone medieval tower with decorative battlements and windows.", category: .structures, emoji: "🏰",
              minScale: 0.7, maxScale: 1.2, footprint: SIMD3(0.08, 0.18, 0.08), compatibleThemes: [.tropical, .coldwater],
              primaryColor: CodableColor(0.60, 0.58, 0.55), secondaryColor: CodableColor(0.45, 0.42, 0.38)),
        .init(id: "treasure_chest", name: "Treasure Chest", description: "Open treasure chest spilling gold coins on the substrate.", category: .structures, emoji: "💰",
              minScale: 0.6, maxScale: 1.0, footprint: SIMD3(0.07, 0.05, 0.05), compatibleThemes: [],
              primaryColor: CodableColor(0.55, 0.38, 0.18), secondaryColor: CodableColor(0.90, 0.72, 0.10)),
        // NOVELTY
        .init(id: "diver_figurine", name: "Diver Figurine", description: "A tiny ceramic scuba diver exploring your tank floor.", category: .novelty, emoji: "🤿",
              minScale: 0.5, maxScale: 0.9, footprint: SIMD3(0.04, 0.08, 0.03), compatibleThemes: [],
              primaryColor: CodableColor(0.20, 0.45, 0.80), secondaryColor: CodableColor(0.10, 0.30, 0.60)),
        .init(id: "bubble_wand", name: "Bubble Wand", description: "Ornamental wand that produces a curtain of fine bubbles.", category: .novelty, emoji: "🫧",
              minScale: 0.7, maxScale: 1.0, footprint: SIMD3(0.02, 0.12, 0.02), compatibleThemes: [],
              primaryColor: CodableColor(0.70, 0.85, 0.95), secondaryColor: CodableColor(0.50, 0.70, 0.90)),
        .init(id: "pagoda", name: "Stone Pagoda", description: "Multi-tiered miniature pagoda draped in moss and mystery.", category: .novelty, emoji: "🗼",
              minScale: 0.6, maxScale: 1.1, footprint: SIMD3(0.06, 0.14, 0.06), compatibleThemes: [.zen],
              primaryColor: CodableColor(0.50, 0.48, 0.44), secondaryColor: CodableColor(0.22, 0.48, 0.22)),
    ]

    static func items(for category: DecorationCategory) -> [DecorationItem] {
        catalog.filter { $0.category == category }
    }
}
