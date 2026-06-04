import RealityKit
import Foundation
import UIKit

// MARK: - Tank Builder
// Constructs the full tank entity hierarchy: glass walls, substrate,
// water volume, lighting, and decoration anchors.
// Returns a root Entity whose transform sits at the center of the interior space.

enum TankBuilder {

    static func build(config: TankConfiguration) -> Entity {
        let root = Entity()
        root.name = "tank_root"

        let dims = config.tankSize.dimensions
        let glassThick: Float = 0.004

        // Attach bounds component for the fish behavior system
        var bounds = TankBoundsComponent(halfExtents: dims / 2)
        bounds.wallThickness = glassThick
        root.components[TankBoundsComponent.self] = bounds

        // Glass walls (left, right, front, back, floor)
        addGlassWalls(to: root, dims: dims, thickness: glassThick)

        // Substrate layer
        addSubstrate(to: root, dims: dims, config: config)

        // Water volume (inside the tank, slightly smaller than interior)
        addWater(to: root, dims: dims, config: config)

        // Plants if enabled
        if config.plantsEnabled {
            addProceduralPlants(to: root, dims: dims, config: config)
        }

        // Tank light source
        addLighting(to: root, dims: dims, config: config)

        return root
    }

    // MARK: - Glass Walls

    private static func addGlassWalls(to root: Entity, dims: SIMD3<Float>, thickness: Float) {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(white: 0.95, alpha: 1))
        mat.roughness = .init(floatLiteral: 0.02)
        mat.metallic  = .init(floatLiteral: 0.0)
        mat.blending  = .transparent(opacity: .init(floatLiteral: 0.06))

        let w = dims.x; let h = dims.y; let d = dims.z
        let t = thickness

        let walls: [(SIMD3<Float>, SIMD3<Float>)] = [
            // (size, position)
            (SIMD3(t, h + t * 2, d + t * 2), SIMD3(-w / 2 - t / 2, 0, 0)),   // left
            (SIMD3(t, h + t * 2, d + t * 2), SIMD3( w / 2 + t / 2, 0, 0)),   // right
            (SIMD3(w + t * 2, h + t * 2, t), SIMD3(0, 0, -d / 2 - t / 2)),   // back
            (SIMD3(w + t * 2, h + t * 2, t), SIMD3(0, 0,  d / 2 + t / 2)),   // front
            (SIMD3(w + t * 2, t, d + t * 2), SIMD3(0, -h / 2 - t / 2, 0)),   // floor
        ]

        for (size, pos) in walls {
            let mesh   = MeshResource.generateBox(size: size, cornerRadius: 0.001)
            let entity = ModelEntity(mesh: mesh, materials: [mat])
            entity.name = "glass_wall"
            entity.position = pos
            root.addChild(entity)
        }

        // Frame edges (opaque dark trim)
        addFrameEdges(to: root, dims: dims, thickness: t)
    }

    private static func addFrameEdges(to root: Entity, dims: SIMD3<Float>, thickness t: Float) {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(white: 0.15, alpha: 1))
        mat.roughness = .init(floatLiteral: 0.3)
        mat.metallic  = .init(floatLiteral: 0.4)

        let w = dims.x; let h = dims.y; let d = dims.z
        let edgeR: Float = 0.006

        // 12 edges of the box
        let horizontalEdgeY: [(Float, Float)] = [(-h/2, -d/2), (-h/2, d/2), (h/2, -d/2), (h/2, d/2)]
        for (y, z) in horizontalEdgeY {
            let mesh   = MeshResource.generateBox(size: SIMD3(w + t * 2 + edgeR * 2, edgeR, edgeR), cornerRadius: edgeR / 2)
            let entity = ModelEntity(mesh: mesh, materials: [mat])
            entity.position = SIMD3(0, y, z)
            root.addChild(entity)
        }

        let verticalEdgeXZ: [(Float, Float)] = [(-w/2, -d/2), (-w/2, d/2), (w/2, -d/2), (w/2, d/2)]
        for (x, z) in verticalEdgeXZ {
            let mesh   = MeshResource.generateBox(size: SIMD3(edgeR, h + t * 2 + edgeR * 2, edgeR), cornerRadius: edgeR / 2)
            let entity = ModelEntity(mesh: mesh, materials: [mat])
            entity.position = SIMD3(x, 0, z)
            root.addChild(entity)
        }
    }

    // MARK: - Substrate

    private static func addSubstrate(to root: Entity, dims: SIMD3<Float>, config: TankConfiguration) {
        let subH: Float = 0.018
        let mesh = MeshResource.generateBox(
            size: SIMD3(dims.x - 0.002, subH, dims.z - 0.002),
            cornerRadius: 0.002
        )
        var mat = PhysicallyBasedMaterial()
        let c = config.substrate.color
        mat.baseColor = .init(tint: UIColor(red: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: 1))
        mat.roughness = .init(floatLiteral: 0.9)
        mat.metallic  = .init(floatLiteral: 0.0)

        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.name = "substrate"
        entity.position = SIMD3(0, -dims.y / 2 + subH / 2, 0)
        root.addChild(entity)

        // Scatter substrate pebble proxies
        addSubstratePebbles(to: root, dims: dims, color: c, baseY: -dims.y / 2 + subH)
    }

    private static func addSubstratePebbles(to root: Entity, dims: SIMD3<Float>, color: SIMD4<Float>, baseY: Float) {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(red: CGFloat(color.x * 0.85), green: CGFloat(color.y * 0.85), blue: CGFloat(color.z * 0.85), alpha: 1))
        mat.roughness = .init(floatLiteral: 0.95)

        for _ in 0..<20 {
            let r = Float.random(in: 0.004...0.009)
            let mesh = MeshResource.generateSphere(radius: r)
            let entity = ModelEntity(mesh: mesh, materials: [mat])
            entity.position = SIMD3(
                Float.random(in: -(dims.x / 2 - 0.01)...(dims.x / 2 - 0.01)),
                baseY + r,
                Float.random(in: -(dims.z / 2 - 0.01)...(dims.z / 2 - 0.01))
            )
            root.addChild(entity)
        }
    }

    // MARK: - Water Volume

    private static func addWater(to root: Entity, dims: SIMD3<Float>, config: TankConfiguration) {
        let wc = config.theme.waterColor
        let mesh = MeshResource.generateBox(
            size: SIMD3(dims.x - 0.004, dims.y - 0.022, dims.z - 0.004),
            cornerRadius: 0.002
        )
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(red: CGFloat(wc.x), green: CGFloat(wc.y), blue: CGFloat(wc.z), alpha: 1))
        mat.roughness = .init(floatLiteral: 0.05)
        mat.metallic  = .init(floatLiteral: 0.0)
        mat.blending  = .transparent(opacity: .init(floatLiteral: wc.w))

        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.name = "water"
        entity.position = SIMD3(0, 0.01, 0)   // slightly above center to account for substrate
        root.addChild(entity)
    }

    // MARK: - Procedural Plants (simple placeholder geometry)

    private static func addProceduralPlants(to root: Entity, dims: SIMD3<Float>, config: TankConfiguration) {
        let plantCount = Int.random(in: 4...8)
        let baseY = -dims.y / 2 + 0.018

        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(red: 0.15, green: 0.55, blue: 0.20, alpha: 1))
        mat.roughness = .init(floatLiteral: 0.8)

        for _ in 0..<plantCount {
            let h = Float.random(in: 0.04...dims.y * 0.6)
            let w: Float = 0.008
            let mesh = MeshResource.generateBox(size: SIMD3(w, h, w * 0.4), cornerRadius: w / 2)
            let entity = ModelEntity(mesh: mesh, materials: [mat])
            let x = Float.random(in: -(dims.x * 0.4)...(dims.x * 0.4))
            let z = Float.random(in: -(dims.z * 0.4)...(dims.z * 0.4))
            entity.position = SIMD3(x, baseY + h / 2, z)
            // Slight tilt for natural look
            let tilt = Float.random(in: -0.15...0.15)
            entity.orientation = simd_quatf(angle: tilt, axis: SIMD3(0, 0, 1))
            root.addChild(entity)
        }
    }

    // MARK: - Lighting

    private static func addLighting(to root: Entity, dims: SIMD3<Float>, config: TankConfiguration) {
        let lightEntity = Entity()
        lightEntity.name = "tank_light"
        lightEntity.position = SIMD3(0, dims.y / 2 - 0.02, 0)

        var light = PointLightComponent()
        light.intensity = config.lighting.lightIntensity
        let lc = config.lighting.lightColor
        light.color = UIColor(red: CGFloat(lc.x), green: CGFloat(lc.y), blue: CGFloat(lc.z), alpha: 1)
        light.attenuationRadius = max(dims.x, dims.y, dims.z) * 2

        lightEntity.components[PointLightComponent.self] = light
        root.addChild(lightEntity)
    }

    // MARK: - Live Updates

    static func updateLighting(root: Entity, config: TankConfiguration) {
        guard let lightEntity = root.findEntity(named: "tank_light") else { return }
        let lc = config.lighting.lightColor
        var light = PointLightComponent()
        light.intensity = config.lighting.lightIntensity
        light.color = UIColor(red: CGFloat(lc.x), green: CGFloat(lc.y), blue: CGFloat(lc.z), alpha: 1)
        light.attenuationRadius = 2.0
        lightEntity.components[PointLightComponent.self] = light
    }

    static func updateWater(root: Entity, config: TankConfiguration) {
        guard let water = root.findEntity(named: "water") as? ModelEntity else { return }
        let wc = config.theme.waterColor
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(red: CGFloat(wc.x), green: CGFloat(wc.y), blue: CGFloat(wc.z), alpha: 1))
        mat.roughness = .init(floatLiteral: 0.05)
        mat.blending  = .transparent(opacity: .init(floatLiteral: wc.w))
        water.model?.materials = [mat]
    }
}
