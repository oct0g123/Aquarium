import SwiftUI
import RealityKit

// What the user has tapped in the tank — drives the floating info card.
enum TankSelection: Equatable {
    case fish(UUID)
    case decoration(UUID)
}

// The volumetric window containing the 3D aquarium tank.
struct AquariumVolumeView: View {
    @Environment(AppModel.self) private var appModel

    @State private var selection: TankSelection? = nil
    @State private var dragStartPositions: [UUID: SIMD3<Float>] = [:]

    var body: some View {
        RealityView { content, attachments in
            let tank = TankBuilder.build(config: appModel.store.tankConfig)
            content.add(tank)
            appModel.tankRoot = tank

            FishComponent.registerComponent()
            TankBoundsComponent.registerComponent()
            DecorationComponent.registerComponent()
            FoodComponent.registerComponent()
            FishBehaviorSystem.registerSystem()
            FoodSystem.registerSystem()

            for instance in appModel.store.fish        { spawnFish(instance: instance, root: tank) }
            for instance in appModel.store.decorations { spawnDecoration(instance: instance, root: tank) }

            if appModel.store.tankConfig.bubblesEnabled {
                tank.addChild(BubbleEmitter.makeAmbient(tankDims: appModel.store.tankConfig.tankSize.dimensions))
            }
            AquariumAudio.attachAmbience(to: tank, volume: 0.35)

            if let card = attachments.entity(for: "infoCard") {
                card.name = "infoCardAttachment"
                card.isEnabled = false
                tank.addChild(card)
            }

        } update: { content, attachments in
            guard let tank = appModel.tankRoot else { return }
            syncFish(root: tank)
            syncDecorations(root: tank)
            TankBuilder.updateLighting(root: tank, config: appModel.store.tankConfig)
            TankBuilder.updateWater(root: tank, config: appModel.store.tankConfig)
            positionInfoCard(in: tank)

        } attachments: {
            Attachment(id: "infoCard") {
                infoCardContent
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in handleTap(on: value.entity) }
        )
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { handleDragChanged($0) }
                .onEnded   { handleDragEnded($0) }
        )
        .ornament(attachmentAnchor: .scene(.topLeading), contentAlignment: .bottomTrailing) {
            statusBadges
        }
        .ornament(attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
            controlsToolbar
        }
        // Tell AppModel when this window is closed so ContentView button resets
        .onDisappear {
            appModel.volumeIsOpen = false
            appModel.tankRoot = nil
            appModel.liveEntityIDs.removeAll()
            appModel.liveDecorationIDs.removeAll()
        }
    }

    // MARK: - Info Card Content

    @ViewBuilder
    private var infoCardContent: some View {
        switch selection {
        case .fish(let id):
            if let instance = appModel.store.fish.first(where: { $0.id == id }),
               let species = instance.species {
                FishInfoCard(
                    species: species,
                    nickname: instance.nickname,
                    onRemove: {
                        appModel.store.removeFish(instance)
                        selection = nil
                    },
                    onClose: { selection = nil }
                )
            }
        case .decoration(let id):
            if let instance = appModel.store.decorations.first(where: { $0.id == id }),
               let item = instance.item {
                DecorationInfoCard(
                    item: item,
                    onRemove: {
                        appModel.store.removeDecoration(id)
                        selection = nil
                    },
                    onClose: { selection = nil }
                )
            }
        case nil:
            EmptyView()
        }
    }

    // MARK: - Fish

    private func spawnFish(instance: FishInstance, root: Entity) {
        guard let species = instance.species else { return }
        let entity = FishEntityFactory.makeEntity(for: species, instanceID: instance.id)
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

    // MARK: - Decorations

    private func spawnDecoration(instance: DecorationInstance, root: Entity) {
        guard let entity = DecorationEntityFactory.makeEntity(for: instance) else { return }
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

    // MARK: - Tap

    private func handleTap(on entity: Entity) {
        var current: Entity? = entity
        while let e = current {
            if let comp = e.components[FishComponent.self] {
                selection = .fish(comp.instanceID)
                return
            }
            if let comp = e.components[DecorationComponent.self] {
                selection = .decoration(comp.instanceID)
                return
            }
            current = e.parent
        }
        selection = nil
    }

    // MARK: - Drag (decorations only)

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
        if dragStartPositions[comp.instanceID] == nil {
            dragStartPositions[comp.instanceID] = decor.position
        }
        guard let start = dragStartPositions[comp.instanceID] else { return }
        let t = value.convert(value.translation3D, from: .local, to: .scene)
        var newPos = start + SIMD3(Float(t.x), Float(t.y), Float(t.z))
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

    private func positionInfoCard(in tank: Entity) {
        guard let card = tank.findEntity(named: "infoCardAttachment") else { return }
        var targetEntity: Entity?

        switch selection {
        case .fish(let id):        targetEntity = appModel.liveEntityIDs[id]
        case .decoration(let id): targetEntity = appModel.liveDecorationIDs[id]
        case nil:                  break
        }

        guard let anchor = targetEntity else {
            card.isEnabled = false
            return
        }
        card.isEnabled = true
        card.position = anchor.position + SIMD3(0, 0.09, 0.05)
    }

    // MARK: - Feeding

    private func dropFood() {
        guard let tank = appModel.tankRoot else { return }
        let dims = appModel.store.tankConfig.tankSize.dimensions
        let topY = dims.y / 2 - 0.03
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
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            Label(appModel.store.stats.moodLabel, systemImage: "heart.fill")
                .font(.caption2.bold())
                .foregroundStyle(.pink)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(8)
    }

    private var controlsToolbar: some View {
        HStack(spacing: 14) {
            Button { dropFood() } label: {
                Label("Feed", systemImage: "drop.fill")
            }
            .tint(.orange)

            Divider().frame(height: 22)

            Button {
                appModel.catalogTab = .fish
                appModel.showCatalog = true
            } label: { Label("Fish", systemImage: "fish.fill") }

            Button {
                appModel.catalogTab = .decorations
                appModel.showCatalog = true
            } label: { Label("Decor", systemImage: "leaf.fill") }

            Button {
                appModel.catalogTab = .themes
                appModel.showCatalog = true
            } label: { Label("Theme", systemImage: "paintbrush.fill") }
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 16)
        .sheet(isPresented: Binding(
            get: { appModel.showCatalog },
            set: { appModel.showCatalog = $0 }
        )) {
            CatalogSheet().environment(appModel)
        }
    }
}
