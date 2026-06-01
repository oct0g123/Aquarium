import RealityKit
import Foundation

// MARK: - Decoration Entity Factory
// Builds RealityKit entities for placed decorations using procedural geometry.
// Each entity carries a DecorationComponent so taps and drags can resolve
// back to the owning DecorationInstance.
// When USDZ models are available, replace the per-category mesh builders with
// ModelEntity(named: item.id, in: assetsBundle).

struct DecorationComponent: Component {
    var instanceID: UUID
    var itemID: String
}

enum DecorationEntityFactory {

    static func makeEntity(for instance: DecorationInstance) -> Entity? {
        guard let item = instance.item else { return nil }

        let root = Entity()
        root.name = "decor_\(instance.id.uuidString.prefix(8))"
        root.components[DecorationComponent.self] = DecorationComponent(
            instanceID: instance.id,
            itemID: item.id
        )

        // Build category-specific geometry
        let visual: Entity
        switch item.category {
        case .plants:     visual = makePlant(item: item)
        case .hardscape:  visual = makeRock(item: item)
        case .structures: visual = makeStructure(item: item)
        case .substrate:  visual = makeRock(item: item)
        case .novelty:    visual = makeNovelty(item: item)
        }
        root.addChild(visual)

        // Apply saved transform
        root.position = instance.position.simd
        root.orientation = simd_quatf(angle: instance.yRotation, axis: SIMD3(0, 1, 0))
        root.scale = SIMD3(repeating: instance.scale)

        // Make the whole decoration interactive (tap + drag)
        let bounds = visual.visualBounds(relativeTo: root)
        root.components.set(InputTargetComponent())
        root.components.set(CollisionComponent(shapes: [
            .generateBox(size: max(bounds.extents, SIMD3(repeating: 0.02)))
        ]))
        root.components.set(HoverEffectComponent())

        return root
    }

    // MARK: - Material helper

    private static func material(_ color: CodableColor, roughness: Float = 0.8, metallic: Float = 0.0) -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: color.uiColor)
        mat.roughness = .init(floatLiteral: roughness)
        mat.metallic  = .init(floatLiteral: metallic)
        return mat
    }

    // MARK: - Plants
    // Cluster of upright blades that fan out from a base.
    private static func makePlant(item: DecorationItem) -> Entity {
        let root = Entity()
        let h = item.footprint.y
        let bladeCount = Int.random(in: 5...9)

        for i in 0..<bladeCount {
            let bladeH = h * Float.random(in: 0.6...1.0)
            let w = item.footprint.x * 0.25
            let mesh = MeshResource.generateBox(size: SIMD3(w, bladeH, w * 0.3), cornerRadius: w / 2)
            // Alternate primary/secondary color for depth
            let mat = material(i % 2 == 0 ? item.primaryColor : item.secondaryColor, roughness: 0.85)
            let blade = ModelEntity(mesh: mesh, materials: [mat])
            let angle = Float(i) / Float(bladeCount) * 2 * .pi
            let spread = item.footprint.x * 0.25
            blade.position = SIMD3(cos(angle) * spread, bladeH / 2, sin(angle) * spread)
            // Splay outward
            let tilt = Float.random(in: 0.05...0.25)
            blade.orientation = simd_quatf(angle: tilt, axis: SIMD3(-sin(angle), 0, cos(angle)))
            root.addChild(blade)
        }
        return root
    }

    // MARK: - Hardscape (rocks)
    // A clump of irregular boulders.
    private static func makeRock(item: DecorationItem) -> Entity {
        let root = Entity()
        let clumpCount = Int.random(in: 2...4)

        for _ in 0..<clumpCount {
            let r = item.footprint.x * Float.random(in: 0.3...0.6)
            let mesh = MeshResource.generateSphere(radius: r)
            let mat = material(Bool.random() ? item.primaryColor : item.secondaryColor, roughness: 0.95)
            let rock = ModelEntity(mesh: mesh, materials: [mat])
            rock.position = SIMD3(
                Float.random(in: -r...r),
                r * 0.7,
                Float.random(in: -r...r)
            )
            // Squash slightly so rocks look settled, not spherical
            rock.scale = SIMD3(1.0, Float.random(in: 0.6...0.85), 1.0)
            root.addChild(rock)
        }
        return root
    }

    // MARK: - Structures (ships, ruins, gates, castles)
    private static func makeStructure(item: DecorationItem) -> Entity {
        let root = Entity()
        let f = item.footprint

        switch item.id {
        case "tori_gate":
            // Two pillars + two crossbeams
            let pillarMesh = MeshResource.generateBox(size: SIMD3(f.x * 0.18, f.y, f.x * 0.18), cornerRadius: 0.003)
            let mat = material(item.primaryColor, roughness: 0.6)
            for side in [-1, 1] as [Float] {
                let pillar = ModelEntity(mesh: pillarMesh, materials: [mat])
                pillar.position = SIMD3(side * f.x * 0.4, f.y / 2, 0)
                root.addChild(pillar)
            }
            let topMesh = MeshResource.generateBox(size: SIMD3(f.x * 1.15, f.y * 0.12, f.x * 0.22), cornerRadius: 0.003)
            let top = ModelEntity(mesh: topMesh, materials: [mat])
            top.position = SIMD3(0, f.y * 0.95, 0)
            root.addChild(top)
            let midMesh = MeshResource.generateBox(size: SIMD3(f.x * 0.95, f.y * 0.08, f.x * 0.2), cornerRadius: 0.002)
            let mid = ModelEntity(mesh: midMesh, materials: [mat])
            mid.position = SIMD3(0, f.y * 0.72, 0)
            root.addChild(mid)

        case "castle_tower", "pagoda":
            // Stacked tapering tiers
            let tiers = item.id == "pagoda" ? 4 : 3
            let mat = material(item.primaryColor, roughness: 0.8)
            for t in 0..<tiers {
                let frac = 1.0 - Float(t) / Float(tiers + 1)
                let tierH = f.y / Float(tiers)
                let mesh = MeshResource.generateBox(size: SIMD3(f.x * frac, tierH, f.z * frac), cornerRadius: 0.004)
                let tier = ModelEntity(mesh: mesh, materials: [mat])
                tier.position = SIMD3(0, tierH * Float(t) + tierH / 2, 0)
                root.addChild(tier)
                // Pagoda roofs (secondary color slabs between tiers)
                if item.id == "pagoda" {
                    let roofMesh = MeshResource.generateBox(size: SIMD3(f.x * frac * 1.3, tierH * 0.12, f.z * frac * 1.3), cornerRadius: 0.003)
                    let roof = ModelEntity(mesh: roofMesh, materials: [material(item.secondaryColor)])
                    roof.position = SIMD3(0, tierH * Float(t) + tierH, 0)
                    root.addChild(roof)
                }
            }

        case "sunken_ship":
            // Hull + mast, tilted as if wrecked
            let hullMesh = MeshResource.generateBox(size: SIMD3(f.x, f.y * 0.5, f.z), cornerRadius: f.z * 0.4)
            let hull = ModelEntity(mesh: hullMesh, materials: [material(item.primaryColor, roughness: 0.9)])
            hull.position = SIMD3(0, f.y * 0.25, 0)
            root.addChild(hull)
            let mastMesh = MeshResource.generateBox(size: SIMD3(f.x * 0.04, f.y * 0.9, f.x * 0.04), cornerRadius: 0.002)
            let mast = ModelEntity(mesh: mastMesh, materials: [material(item.secondaryColor)])
            mast.position = SIMD3(0, f.y * 0.6, 0)
            root.addChild(mast)
            root.orientation = simd_quatf(angle: 0.2, axis: SIMD3(0, 0, 1))

        case "roman_ruins":
            // A few broken columns of varying heights
            let mat = material(item.primaryColor, roughness: 0.85)
            for i in 0..<3 {
                let colH = f.y * Float.random(in: 0.4...1.0)
                let mesh = MeshResource.generateCylinder(height: colH, radius: f.x * 0.12)
                let col = ModelEntity(mesh: mesh, materials: [mat])
                col.position = SIMD3(Float(i - 1) * f.x * 0.35, colH / 2, Float.random(in: -f.z * 0.2...f.z * 0.2))
                root.addChild(col)
            }

        default: // treasure_chest and any other structure
            let baseMesh = MeshResource.generateBox(size: SIMD3(f.x, f.y * 0.6, f.z), cornerRadius: 0.004)
            let base = ModelEntity(mesh: baseMesh, materials: [material(item.primaryColor, roughness: 0.7, metallic: 0.2)])
            base.position = SIMD3(0, f.y * 0.3, 0)
            root.addChild(base)
            // Gold lid
            let lidMesh = MeshResource.generateBox(size: SIMD3(f.x, f.y * 0.25, f.z), cornerRadius: 0.004)
            let lid = ModelEntity(mesh: lidMesh, materials: [material(item.secondaryColor, roughness: 0.3, metallic: 0.8)])
            lid.position = SIMD3(0, f.y * 0.62, -f.z * 0.3)
            lid.orientation = simd_quatf(angle: -0.5, axis: SIMD3(1, 0, 0))
            root.addChild(lid)
        }
        return root
    }

    // MARK: - Novelty (diver, bubble wand, etc.)
    private static func makeNovelty(item: DecorationItem) -> Entity {
        let root = Entity()
        let f = item.footprint

        if item.id == "bubble_wand" {
            let mesh = MeshResource.generateCylinder(height: f.y, radius: f.x * 0.4)
            let wand = ModelEntity(mesh: mesh, materials: [material(item.primaryColor, roughness: 0.2)])
            wand.position = SIMD3(0, f.y / 2, 0)
            root.addChild(wand)
            // Bubble emitter is attached separately by BubbleEmitter
        } else {
            // Generic figurine: body sphere + head sphere
            let bodyMesh = MeshResource.generateSphere(radius: f.x * 0.5)
            let body = ModelEntity(mesh: bodyMesh, materials: [material(item.primaryColor, roughness: 0.6)])
            body.position = SIMD3(0, f.y * 0.35, 0)
            body.scale = SIMD3(1, 1.4, 1)
            root.addChild(body)
            let headMesh = MeshResource.generateSphere(radius: f.x * 0.32)
            let head = ModelEntity(mesh: headMesh, materials: [material(item.secondaryColor, roughness: 0.5)])
            head.position = SIMD3(0, f.y * 0.75, 0)
            root.addChild(head)
        }
        return root
    }
}
