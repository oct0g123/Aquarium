import SwiftUI
import RealityKit

// The volumetric window containing the 3D aquarium tank.
// This view IS the tank — fish swim here, decorations sit here.
struct AquariumVolumeView: View {
    @Environment(AppModel.self) private var appModel

    // Tap-to-inspect state
    @State private var selectedFishID: UUID? = nil

    // Drag-to-reposition state
    @State private var dragStartPositions: [UUID: SIMD3<Float>] = [:]

    var body: some View {
        RealityView { content, attachments in
            let tank = TankBuilder.build(config: appModel.store.tankConfig)
            content.add(tank)
            appModel.tankRoot = tank

            // Register ECS
            registerECS()

            // Spawn fish
            for instance in appModel.store.fish {
                spawnFish(instance: instance, root: tank)
            }

            // Spawn saved decorations
            for instance in appModel.store.decorations {
                spawnDecoration(instance: instance, root: tank)
            }

            // Ambient bubbles + bubble-wand emitters
            if appModel.store.tankConfig.bubblesEnabled {
                tank.addChild(BubbleEmitter.makeAmbient(tankDims: appModel.store.tankConfig.tankSize.dimensions))
            }

            // Spatial ambience emanating from the tank
            AquariumAudio.attachAmbience(to: tank, volume: 0.35)

            // Attach the fish-info card (hidden until a fish is tapped)
            if let infoCard = attachments.entity(for: "fishInfo") {
                infoCard.name = "fishInfoAttachment"
                infoCard.isEnabled = false
                tank.addChild(infoCard)
            }

        } update: { content, attachments in
            guard let tank = appModel.tankRoot else { return }

            syncFish(root: tank)
            syncDecorations(root: tank)

            // Update tank appearance when config changes
            TankBuilder.updateLighting(root: tank, config: appModel.store.tankConfig)
            TankBuilder.updateWater(root: tank, config: appModel.store.tankConfig)

            // Position the info card next to the selected fish
            updateInfoCard(in: tank)

        } attachments: {
            Attachment(id: "fishInfo") {
                if let id = selectedFishID,
                   let instance = appModel.store.fish.first(where: { $0.id == id }),
                   let species = instance.species {
                    FishInfoCard(
                        species: species,
                        nickname: instance.nickname,
                        onRemove: {
                            appModel.store.removeFish(instance)
                            selectedFishID = nil
                        },
                        onClose: { selectedFishID = nil }
                    )
                }
            }
        }
        // Tap: inspect fish, or dismiss the card when tapping elsewhere
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in handleTap(on: value.entity) }
        )
        // Drag: reposition decorations
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in handleDragChanged(value) }
                .onEnded { value in handleDragEnded(value) }
        )
        .ornament(attachmentAnchor: .scene(.topLeading), contentAlignment: .bottomTrailing) {
            statusBadges
        }
        .ornament(attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
            controlsToolbar
        }
    }

    // MARK: - ECS Registration

    private func registerECS() {
        FishComponent.registerComponent()
        TankBoundsComponent.registerComponent()
        DecorationComponent.registerComponent()
        FoodComponent.registerComponent()
        FishBehaviorSystem.registerSystem()
        FoodSystem.registerSystem()
    }

    // MARK: - Fish Spawning & Sync

    private func spawnFish(instance: FishInstance, root: Entity) {
        guard let species = instance.species else { return }
        let entity = FishEntityFactory.makeEntity(for: species, instanceID: instance.id)

        // Make fish tappable
        entity.components.set(InputTargetComponent())
        entity.components.set(CollisionComponent(shapes: [
            .generateSphere(radius: max(species.bodyLength * 0.6, 0.03))
        ]))
        entity.components.set(HoverEffectComponent())

        let dims = appModel.store.tankConfig.tankSize.dimensions
        entity.position = SIMD3(
            Float.random(in: -(dims.x * 0.4)...(dims.x * 0.4)),
            Float.random(in: -(dims.y * 0.25)...(dims.y * 0.25)),
            Float.random(in: -(dims.z * 0.35)...(dims.z * 0.35))
        )
        root.addChild(entity)
        appModel.liveEntityIDs[instance.id] = entity
    }

    private func syncFish(root: Entity) {
        let storeIDs = Set(appModel.store.fish.map(\.id))
        let liveIDs  = Set(appModel.liveEntityIDs.keys)

        for id in liveIDs.subtracting(storeIDs) {
            appModel.liveEntityIDs[id]?.removeFromParent()
            appModel.liveEntityIDs.removeValue(forKey: id)
        }
        for instance in appModel.store.fish where !liveIDs.contains(instance.id) {
            spawnFish(instance: instance, root: root)
        }
    }

    // MARK: - Decoration Spawning & Sync

    private func spawnDecoration(instance: DecorationInstance, root: Entity) {
        guard let entity = DecorationEntityFactory.makeEntity(for: instance) else { return }
        // Bubble wand emits bubbles
        if instance.itemID == "bubble_wand", appModel.store.tankConfig.bubblesEnabled {
            let col = BubbleEmitter.makeColumn(height: 0.2, intensity: 0.7)
            col.position = SIMD3(0, instance.item?.footprint.y ?? 0.12, 0)
            entity.addChild(col)
        }
        root.addChild(entity)
        appModel.liveDecorationIDs[instance.id] = entity
    }

    private func syncDecorations(root: Entity) {
        let storeIDs = Set(appModel.store.decorations.map(\.id))
        let liveIDs  = Set(appModel.liveDecorationIDs.keys)

        for id in liveIDs.subtracting(storeIDs) {
            appModel.liveDecorationIDs[id]?.removeFromParent()
            appModel.liveDecorationIDs.removeValue(forKey: id)
        }
        for instance in appModel.store.decorations where !liveIDs.contains(instance.id) {
            spawnDecoration(instance: instance, root: root)
        }
    }

    // MARK: - Tap Handling

    private func handleTap(on entity: Entity) {
        // Walk up to find a fish entity
        var current: Entity? = entity
        while let e = current {
            if let comp = e.components[FishComponent.self] {
                selectedFishID = comp.instanceID
                return
            }
            current = e.parent
        }
        // Tapped something that isn't a fish — dismiss the card
        selectedFishID = nil
    }

    // MARK: - Drag Handling (decorations)

    private func decorationRoot(from entity: Entity) -> Entity? {
        var current: Entity? = entity
        while let e = current {
            if e.components[DecorationComponent.self] != nil { return e }
            current = e.parent
        }
        return nil
    }

    private func handleDragChanged(_ value: EntityTargetValue<DragGesture.Value>) {
        guard let decor = decorationRoot(from: value.entity),
              let comp = decor.components[DecorationComponent.self] else { return }

        // Record the starting position once per drag
        if dragStartPositions[comp.instanceID] == nil {
            dragStartPositions[comp.instanceID] = decor.position
        }
        guard let start = dragStartPositions[comp.instanceID] else { return }

        // Convert the SwiftUI drag translation into tank-local space
        let translation = value.convert(value.translation3D, from: .local, to: .scene)
        var newPos = start + SIMD3(Float(translation.x), Float(translation.y), Float(translation.z))

        // Keep the decoration inside the tank and resting near the floor
        if let bounds = appModel.tankRoot?.components[TankBoundsComponent.self] {
            newPos = simd_clamp(newPos, bounds.minBound, bounds.maxBound)
            newPos.y = max(newPos.y, bounds.floorY)
        }
        decor.position = newPos
    }

    private func handleDragEnded(_ value: EntityTargetValue<DragGesture.Value>) {
        guard let decor = decorationRoot(from: value.entity),
              let comp = decor.components[DecorationComponent.self] else { return }
        appModel.store.updateDecoration(comp.instanceID, position: decor.position)
        dragStartPositions[comp.instanceID] = nil
    }

    // MARK: - Info Card Positioning

    private func updateInfoCard(in tank: Entity) {
        guard let card = tank.findEntity(named: "fishInfoAttachment") else { return }
        guard let id = selectedFishID, let fishEntity = appModel.liveEntityIDs[id] else {
            card.isEnabled = false
            return
        }
        card.isEnabled = true
        // Float the card just above and in front of the fish, facing the viewer
        card.position = fishEntity.position + SIMD3(0, 0.08, 0.04)
        card.orientation = simd_quatf(angle: 0, axis: SIMD3(0, 1, 0))
    }

    // MARK: - Feeding

    private func dropFood() {
        guard let tank = appModel.tankRoot else { return }
        let dims = appModel.store.tankConfig.tankSize.dimensions
        let topY = dims.y / 2 - 0.03
        // Scatter a small handful of pellets near the surface
        for _ in 0..<Int.random(in: 4...7) {
            let pellet = FoodPellet.make()
            pellet.position = SIMD3(
                Float.random(in: -(dims.x * 0.3)...(dims.x * 0.3)),
                topY,
                Float.random(in: -(dims.z * 0.3)...(dims.z * 0.3))
            )
            tank.addChild(pellet)
        }
        AquariumAudio.playFeedBlip(on: tank)
        appModel.store.recordFeeding()
    }

    // MARK: - Ornaments

    private var statusBadges: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(appModel.fishCountLabel, systemImage: "fish.fill")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            Label(appModel.store.stats.moodLabel, systemImage: "heart.fill")
                .font(.caption2.bold())
                .foregroundStyle(.pink)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(8)
    }

    private var controlsToolbar: some View {
        HStack(spacing: 14) {
            Button {
                dropFood()
            } label: {
                Label("Feed", systemImage: "drop.fill")
            }
            .tint(.orange)

            Divider().frame(height: 22)

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
