import RealityKit
import Foundation
import UIKit

// MARK: - Food Pellet Component & System
// The first gameification hook: tapping "Feed" drops pellets into the tank.
// Pellets sink slowly; nearby fish break formation and dart toward the closest
// pellet, "eating" it on contact. Purely delightful — no penalties for not
// feeding, matching the zen-aesthetic baseline.

struct FoodComponent: Component {
    static let query = EntityQuery(where: .has(FoodComponent.self))
    var sinkSpeed: Float = 0.03
    var eaten: Bool = false
    var age: Float = 0
    let maxAge: Float = 20   // pellets dissolve if uneaten
}

final class FoodSystem: System {
    private static let eatRadius: Float = 0.025
    private static let seekRadius: Float = 0.30   // fish notice food within this range

    required init(scene: Scene) {}

    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        guard dt > 0, dt < 0.2 else { return }

        // Tank floor (so pellets settle instead of falling forever).
        // QueryResult is a Sequence (not a Collection), so iterate to read the
        // first match rather than using `.first`.
        let boundsQuery = EntityQuery(where: .has(TankBoundsComponent.self))
        var floorY: Float = -0.2
        for boundsEntity in context.scene.performQuery(boundsQuery) {
            if let bounds = boundsEntity.components[TankBoundsComponent.self] {
                floorY = bounds.floorY
                break
            }
        }

        // Gather pellets
        var pellets: [(entity: Entity, comp: FoodComponent)] = []
        for entity in context.scene.performQuery(FoodComponent.query) {
            if let comp = entity.components[FoodComponent.self] {
                pellets.append((entity, comp))
            }
        }
        guard !pellets.isEmpty else { return }

        // Sink + age pellets
        for (entity, var comp) in pellets {
            comp.age += dt
            if entity.position.y > floorY + 0.01 {
                entity.position.y -= comp.sinkSpeed * dt
            }
            // Dissolve old pellets by shrinking, then removing
            if comp.age > comp.maxAge {
                let remaining = max(0, 1 - (comp.age - comp.maxAge))
                entity.scale = SIMD3(repeating: remaining)
                if remaining <= 0.01 { entity.removeFromParent(); continue }
            }
            entity.components[FoodComponent.self] = comp
        }

        // Fish seek nearest pellet within range and eat on contact
        for fishEntity in context.scene.performQuery(FishComponent.query) {
            guard var fish = fishEntity.components[FishComponent.self] else { continue }

            var nearest: Entity?
            var nearestDist = Self.seekRadius
            for (pellet, comp) in pellets where !comp.eaten {
                let d = simd_distance(pellet.position, fishEntity.position)
                if d < nearestDist {
                    nearestDist = d
                    nearest = pellet
                }
            }

            guard let target = nearest else {
                // No food in range — return to idle immediately.
                // Resetting wanderTimer=0 forces the behavior system to pick a
                // fresh wander target this frame instead of orbiting the last
                // known food position.
                if fish.isFeeding {
                    fish.isFeeding = false
                    fish.wanderTimer = 0
                    fishEntity.components[FishComponent.self] = fish
                }
                continue
            }

            // Redirect the fish's wander target toward the pellet
            fish.targetPosition = target.position
            fish.isFeeding = true
            fish.wanderTimer = 1.0   // keep heading to food briefly
            fishEntity.components[FishComponent.self] = fish

            // Eat on contact
            if nearestDist < Self.eatRadius,
               var comp = target.components[FoodComponent.self], !comp.eaten {
                comp.eaten = true
                target.components[FoodComponent.self] = comp
                target.removeFromParent()
            }
        }
    }
}

// MARK: - Food Pellet Factory
enum FoodPellet {
    static func make() -> Entity {
        let r = Float.random(in: 0.004...0.007)
        let mesh = MeshResource.generateSphere(radius: r)
        var mat = PhysicallyBasedMaterial()
        // Earthy pellet color
        mat.baseColor = .init(tint: UIColor(red: 0.55, green: 0.40, blue: 0.20, alpha: 1))
        mat.roughness = .init(floatLiteral: 0.9)
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.name = "food_pellet"
        entity.components.set(FoodComponent(sinkSpeed: Float.random(in: 0.02...0.04)))
        return entity
    }
}
