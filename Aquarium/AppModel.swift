import SwiftUI
import RealityKit

enum ImmersiveSpaceState {
    case closed, transitioning, open
}

// Central app state — shared across all scenes via @Environment
@Observable
final class AppModel {
    let store = AquariumStore()

    // Window/space lifecycle
    var immersiveSpaceState: ImmersiveSpaceState = .closed
    var volumeIsOpen: Bool = false

    // Catalog sheet presentation
    var showCatalog: Bool = false
    var catalogTab: CatalogTab = .fish

    // RealityKit scene root (set by AquariumVolumeView, read by decoration placement)
    var tankRoot: Entity? = nil

    // Tracks which fish instance entities are live in the scene
    var liveEntityIDs: [UUID: Entity] = [:]

    enum CatalogTab: String, CaseIterable {
        case fish, decorations, themes
    }

    var fishCountLabel: String {
        "\(store.fish.count) / \(store.tankConfig.tankSize.maxFishCount)"
    }

    var canAddMoreFish: Bool {
        store.fish.count < store.tankConfig.tankSize.maxFishCount
    }
}
