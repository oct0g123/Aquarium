import RealityKit
import Foundation
import UIKit

// MARK: - Fish Entity Factory
// Creates RealityKit entities for each fish species using procedural geometry.
// When USDZ models are available, replace the mesh/material generation in
// makeBodyEntity() with ModelEntity(named: species.id, in: assetsBundle).

enum FishEntityFactory {

    static func makeEntity(for species: FishSpecies, instanceID: UUID) -> Entity {
        let root = Entity()
        root.name = "fish_\(instanceID.uuidString.prefix(8))"

        // Build composite visual from procedural meshes
        let bodyEntity = makeBodyEntity(species: species)
        root.addChild(bodyEntity)

        if species.usesPulseAnimation {
            // Jellyfish: no separate fins, add extra bell rings
            for i in 1...3 {
                let ring = makeJellyfishRing(species: species, index: i)
                root.addChild(ring)
            }
        } else {
            root.addChild(makeDorsalFin(species: species))
            root.addChild(makeTailFin(species: species))
            root.addChild(makePectoralFin(species: species, side: 1))
            root.addChild(makePectoralFin(species: species, side: -1))
        }

        // Attach the ECS component
        var comp = FishComponent(speciesID: species.id, instanceID: instanceID)
        comp.swimSpeed = species.baseSwimSpeed
        comp.behaviorType = species.behavior
        comp.preferredSchoolSize = species.preferredSchoolSize

        switch species.swimmingDepth {
        case .surface:  comp.depthMin = 0.7; comp.depthMax = 1.0
        case .midwater: comp.depthMin = 0.2; comp.depthMax = 0.8
        case .bottom:   comp.depthMin = 0.0; comp.depthMax = 0.25
        case .all:      comp.depthMin = 0.0; comp.depthMax = 1.0
        }

        // Randomize initial phase so fish don't all flap together
        comp.swimPhase = Float.random(in: 0...(2 * .pi))
        // Scatter initial target positions across the tank
        comp.targetPosition = SIMD3(
            Float.random(in: -0.25...0.25),
            Float.random(in: -0.15...0.15),
            Float.random(in: -0.15...0.15)
        )
        comp.velocity = SIMD3(Float.random(in: -0.05...0.05), 0, Float.random(in: -0.05...0.05))
        root.components[FishComponent.self] = comp

        return root
    }

    // MARK: - Body

    private static func makeBodyEntity(species: FishSpecies) -> ModelEntity {
        let length = species.bodyLength
        let height = length * (species.usesPulseAnimation ? 0.5 : 0.35)
        let depth  = length * (species.usesPulseAnimation ? 0.5 : 0.28)

        let mesh: MeshResource
        if species.usesPulseAnimation {
            // Jellyfish bell — flattened sphere
            mesh = try! MeshResource.generate(from: [
                MeshDescriptor.generateEllipsoid(rx: height * 0.9, ry: height * 0.55, rz: depth * 0.9, segments: 24)
            ])
        } else {
            mesh = try! MeshResource.generate(from: [
                MeshDescriptor.generateEllipsoid(rx: length * 0.5, ry: height * 0.5, rz: depth * 0.5, segments: 24)
            ])
        }

        var mat = PhysicallyBasedMaterial()
        mat.baseColor     = .init(tint: species.bodyColor.uiColor)
        mat.roughness     = .init(floatLiteral: 0.35)
        mat.metallic      = .init(floatLiteral: 0.05)

        if species.usesPulseAnimation {
            mat.blending  = .transparent(opacity: .init(floatLiteral: 0.55))
        }

        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.name = "body"
        return entity
    }

    // MARK: - Fins

    private static func makeDorsalFin(species: FishSpecies) -> ModelEntity {
        let h = species.bodyLength * 0.28
        let w = species.bodyLength * 0.08
        let mesh = MeshResource.generateBox(size: SIMD3(w, h, 0.002), cornerRadius: 0.001)
        var mat = finMaterial(species: species)
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.name = "dorsal_fin"
        entity.position = SIMD3(0, species.bodyLength * 0.12, 0)
        return entity
    }

    private static func makeTailFin(species: FishSpecies) -> ModelEntity {
        let tailW = species.bodyLength * (species.behavior == .territorial ? 0.55 : 0.40)
        let tailH = species.bodyLength * (species.behavior == .territorial ? 0.50 : 0.38)
        let mesh = MeshResource.generateBox(size: SIMD3(0.002, tailH, tailW), cornerRadius: 0.001)
        let mat = finMaterial(species: species)
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.name = "tail_fin"
        entity.position = SIMD3(species.bodyLength * 0.48, 0, 0)
        return entity
    }

    private static func makePectoralFin(species: FishSpecies, side: Float) -> ModelEntity {
        let w = species.bodyLength * 0.20
        let h = species.bodyLength * 0.12
        let mesh = MeshResource.generateBox(size: SIMD3(w, 0.001, h), cornerRadius: 0.001)
        let mat = finMaterial(species: species)
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.name = side > 0 ? "pec_fin_left" : "pec_fin_right"
        entity.position = SIMD3(-species.bodyLength * 0.05,
                                 -species.bodyLength * 0.06,
                                  side * species.bodyLength * 0.20)
        return entity
    }

    private static func makeJellyfishRing(species: FishSpecies, index: Int) -> ModelEntity {
        let r = species.bodyLength * 0.4 * Float(index)
        let h: Float = 0.002
        let mesh = MeshResource.generateBox(size: SIMD3(r * 0.04, species.bodyLength * 0.3 / Float(index), 0.002), cornerRadius: 0.001)
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: species.accentColor.uiColor)
        mat.blending  = .transparent(opacity: .init(floatLiteral: 0.35))
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.name = "tentacle_\(index)"
        let angle = Float(index) * 2.094  // 120° apart
        entity.position = SIMD3(cos(angle) * r * 0.6, -species.bodyLength * 0.35, sin(angle) * r * 0.6)
        return entity
    }

    private static func finMaterial(species: FishSpecies) -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: species.finColor.uiColor)
        mat.roughness = .init(floatLiteral: 0.4)
        mat.metallic  = .init(floatLiteral: 0.02)
        mat.blending  = .transparent(opacity: .init(floatLiteral: 0.75))
        return mat
    }
}

// MARK: - CodableColor → UIColor helper
extension CodableColor {
    var uiColor: UIColor { UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1) }
}

// MARK: - Ellipsoid mesh helper
// RealityKit doesn't have a built-in ellipsoid; we build one via UV sphere math.
extension MeshDescriptor {
    static func generateEllipsoid(rx: Float, ry: Float, rz: Float, segments: Int) -> MeshDescriptor {
        var positions: [SIMD3<Float>] = []
        var normals:   [SIMD3<Float>] = []
        var uvs:       [SIMD2<Float>] = []
        var indices:   [UInt32]       = []

        let rings = segments / 2
        let slices = segments

        for ring in 0...rings {
            let phi = Float.pi * Float(ring) / Float(rings)
            for slice in 0...slices {
                let theta = 2 * Float.pi * Float(slice) / Float(slices)
                let x = rx * sin(phi) * cos(theta)
                let y = ry * cos(phi)
                let z = rz * sin(phi) * sin(theta)
                positions.append(SIMD3(x, y, z))
                normals.append(simd_normalize(SIMD3(x / (rx * rx), y / (ry * ry), z / (rz * rz))))
                uvs.append(SIMD2(Float(slice) / Float(slices), Float(ring) / Float(rings)))
            }
        }

        let stride = slices + 1
        for ring in 0..<rings {
            for slice in 0..<slices {
                let a = UInt32(ring * stride + slice)
                let b = UInt32((ring + 1) * stride + slice)
                let c = UInt32((ring + 1) * stride + slice + 1)
                let d = UInt32(ring * stride + slice + 1)
                indices += [a, b, c, a, c, d]
            }
        }

        var desc = MeshDescriptor(name: "ellipsoid")
        desc.positions = MeshBuffer(positions)
        desc.normals   = MeshBuffer(normals)
        desc.textureCoordinates = MeshBuffer(uvs)
        desc.primitives = .triangles(indices)
        return desc
    }
}
