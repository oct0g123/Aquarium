import SwiftUI
import RealityKit

// The volumetric window containing the 3D aquarium tank.
// This view IS the tank — fish swim here, decorations sit here.
struct AquariumVolumeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var sceneReady = false

    var body: some View {
        RealityView { content in
            let tank = TankBuilder.build(config: appModel.store.tankConfig)
            content.add(tank)
            appModel.tankRoot = tank

            // Register ECS
            FishComponent.registerComponent()
            TankBoundsComponent.registerComponent()
            FishBehaviorSystem.registerSystem()

            // Spawn fish for every instance in the store
            for instance in appModel.store.fish {
                spawnFish(instance: instance, root: tank)
            }

            sceneReady = true
        } update: { content in
            guard let tank = appModel.tankRoot else { return }

            // Sync fish: add new, remove deleted
            let storeIDs = Set(appModel.store.fish.map(\.id))
            let liveIDs  = Set(appModel.liveEntityIDs.keys)

            // Remove fish no longer in store
            for id in liveIDs.subtracting(storeIDs) {
                if let entity = appModel.liveEntityIDs[id] {
                    entity.removeFromParent()
                    appModel.liveEntityIDs.removeValue(forKey: id)
                }
            }

            // Spawn newly added fish
            for instance in appModel.store.fish where !liveIDs.contains(instance.id) {
                spawnFish(instance: instance, root: tank)
            }

            // Update tank appearance when config changes
            TankBuilder.updateLighting(root: tank, config: appModel.store.tankConfig)
            TankBuilder.updateWater(root: tank, config: appModel.store.tankConfig)
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    handleTap(on: value.entity)
                }
        )
        // Ornament: fish count badge
        .ornament(
            attachmentAnchor: .scene(.topLeading),
            contentAlignment: .bottomTrailing
        ) {
            fishCountBadge
        }
        // Ornament: controls toolbar
        .ornament(
            attachmentAnchor: .scene(.bottom),
            contentAlignment: .top
        ) {
            controlsToolbar
        }
    }

    // MARK: - Fish Spawning

    private func spawnFish(instance: FishInstance, root: Entity) {
        guard let species = instance.species else { return }
        let entity = FishEntityFactory.makeEntity(for: species, instanceID: instance.id)
        // Scatter spawn positions within the tank bounds
        let dims = appModel.store.tankConfig.tankSize.dimensions
        entity.position = SIMD3(
            Float.random(in: -(dims.x * 0.4)...(dims.x * 0.4)),
            Float.random(in: -(dims.y * 0.25)...(dims.y * 0.25)),
            Float.random(in: -(dims.z * 0.35)...(dims.z * 0.35))
        )
        root.addChild(entity)
        appModel.liveEntityIDs[instance.id] = entity
    }

    private func handleTap(on entity: Entity) {
        // Walk up to find a fish root entity
        var current: Entity? = entity
        while let e = current {
            if let comp = e.components[FishComponent.self],
               let instance = appModel.store.fish.first(where: { $0.id == comp.instanceID }),
               let species = instance.species {
                // TODO: show fish info sheet
                _ = species.commonName
                return
            }
            current = e.parent
        }
    }

    // MARK: - Ornaments

    private var fishCountBadge: some View {
        Label(appModel.fishCountLabel, systemImage: "fish.fill")
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(8)
    }

    private var controlsToolbar: some View {
        HStack(spacing: 16) {
            Button {
                appModel.catalogTab = .fish
                appModel.showCatalog = true
            } label: {
                Label("Fish", systemImage: "fish.fill")
            }

            Button {
                appModel.catalogTab = .decorations
                appModel.showCatalog = true
            } label: {
                Label("Decor", systemImage: "leaf.fill")
            }

            Button {
                appModel.catalogTab = .themes
                appModel.showCatalog = true
            } label: {
                Label("Theme", systemImage: "paintbrush.fill")
            }
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 16)
        .sheet(isPresented: Binding(get: { appModel.showCatalog }, set: { appModel.showCatalog = $0 })) {
            CatalogSheet()
                .environment(appModel)
        }
    }
}
