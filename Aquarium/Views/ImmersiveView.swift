import SwiftUI
import RealityKit

// Full-immersion underwater experience.
// Surrounds the user with an ocean environment and populates it with
// the same fish species from their tank, now swimming at full scale around them.
struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        RealityView { content in
            // Large ocean sphere (inside-facing)
            content.add(makeOceanSphere())

            // Substrate plane
            content.add(makeOceanFloor())

            // Spawn full-scale fish that drift around the user
            let speciesSet = Set(appModel.store.fish.compactMap(\.species))
            for species in speciesSet {
                let count = max(1, appModel.store.fish.filter { $0.speciesID == species.id }.count)
                for _ in 0..<(count * 2) {         // double count for immersive feel
                    let entity = FishEntityFactory.makeEntity(for: species, instanceID: UUID())
                    // Scale up for immersive space (tank fish are compact)
                    entity.scale = SIMD3(repeating: 3.0)
                    entity.position = randomImmersivePosition()
                    content.add(entity)
                }
            }

            // Ambient bubble columns
            for i in 0..<8 {
                content.add(makeBubbleColumn(index: i))
            }

            FishComponent.registerComponent()
            TankBoundsComponent.registerComponent()
            FishBehaviorSystem.registerSystem()
        }
    }

    // MARK: - Environment Geometry

    private func makeOceanSphere() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 25)
        var mat = UnlitMaterial()
        mat.color = .init(tint: UIColor(red: 0.02, green: 0.12, blue: 0.30, alpha: 1))
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        // Flip normals by inverting scale so the sphere renders from inside
        entity.scale = SIMD3(-1, 1, -1)
        entity.name = "ocean_sphere"
        return entity
    }

    private func makeOceanFloor() -> ModelEntity {
        let mesh = MeshResource.generatePlane(width: 50, depth: 50)
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: UIColor(red: 0.55, green: 0.50, blue: 0.40, alpha: 1))
        mat.roughness = .init(floatLiteral: 0.95)
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.position = SIMD3(0, -3.0, 0)
        entity.name = "ocean_floor"
        return entity
    }

    private func makeBubbleColumn(index: Int) -> Entity {
        let root = Entity()
        root.name = "bubble_column_\(index)"
        let angle = Float(index) * (.pi * 2 / 8)
        let radius = Float.random(in: 2...6)
        root.position = SIMD3(cos(angle) * radius, -2.5, sin(angle) * radius)

        // Small sphere bubbles that drift upward (animated in a future pass)
        for j in 0..<5 {
            var mat = PhysicallyBasedMaterial()
            mat.baseColor = .init(tint: UIColor(white: 0.9, alpha: 1))
            mat.blending = .transparent(opacity: .init(floatLiteral: 0.3))
            mat.roughness = .init(floatLiteral: 0.0)
            mat.metallic  = .init(floatLiteral: 0.0)
            let r = Float.random(in: 0.015...0.04)
            let mesh = MeshResource.generateSphere(radius: r)
            let bubble = ModelEntity(mesh: mesh, materials: [mat])
            bubble.position = SIMD3(Float.random(in: -0.1...0.1),
                                    Float(j) * 0.35,
                                    Float.random(in: -0.1...0.1))
            root.addChild(bubble)
        }
        return root
    }

    private func randomImmersivePosition() -> SIMD3<Float> {
        let angle  = Float.random(in: 0...(2 * .pi))
        let radius = Float.random(in: 2.0...8.0)
        let height = Float.random(in: -1.5...2.5)
        return SIMD3(cos(angle) * radius, height, sin(angle) * radius)
    }
}
