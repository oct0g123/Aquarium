import RealityKit
import Foundation

// MARK: - Fish Behavior System
// Updates fish positions every frame using a lightweight boids-inspired algorithm.
// Registered once at app startup via FishBehaviorSystem.registerSystem().

final class FishBehaviorSystem: System {

    // Tuning constants
    private static let wanderInterval: Float      = 3.0   // seconds between target picks
    private static let turnSpeed: Float           = 4.0   // rotational speed (rad/s)
    private static let neighborRadius: Float      = 0.25  // boids cohesion radius
    private static let separationRadius: Float    = 0.08  // boids separation radius
    private static let wallRepelStrength: Float   = 0.35
    private static let swimPhaseRate: Float       = 6.0   // oscillation speed

    // Weight multipliers for each boids force
    private static let cohesionWeight: Float      = 0.4
    private static let separationWeight: Float    = 1.2
    private static let alignmentWeight: Float     = 0.3

    required init(scene: Scene) {}

    func update(context: SceneUpdateContext) {
        let dt = Float(context.deltaTime)
        guard dt > 0, dt < 0.2 else { return }

        // Collect all fish entities for boids neighbor lookup
        var allFish: [(entity: Entity, comp: FishComponent)] = []
        for entity in context.scene.performQuery(FishComponent.query) {
            if let comp = entity.components[FishComponent.self] {
                allFish.append((entity, comp))
            }
        }

        // Find the tank bounds (may be absent in immersive space).
        // QueryResult is a Sequence, not a Collection, so iterate for the first.
        let boundsQuery = EntityQuery(where: .has(TankBoundsComponent.self))
        var bounds: TankBoundsComponent?
        for boundsEntity in context.scene.performQuery(boundsQuery) {
            if let b = boundsEntity.components[TankBoundsComponent.self] {
                bounds = b
                break
            }
        }

        for (entity, var comp) in allFish {
            // 1. Increment swim phase for body oscillation
            comp.swimPhase += dt * Self.swimPhaseRate * (comp.swimSpeed / 0.08)

            // Feeding fish swim faster and ignore schooling/wander so they
            // can dart straight to the pellet FoodSystem assigned them.
            let speed = comp.isFeeding ? comp.swimSpeed * 2.2 : comp.swimSpeed

            // 2. Pick a new wander target when the timer expires or we are close
            comp.wanderTimer -= dt
            let distToTarget = simd_length(comp.targetPosition - entity.position)

            if !comp.isFeeding, comp.wanderTimer <= 0 || distToTarget < 0.04 {
                comp.targetPosition = randomTarget(comp: comp, bounds: bounds)
                comp.wanderTimer = Self.wanderInterval + Float.random(in: -1.0...1.0)
            }

            // 3. Build steering force
            var steering = simd_normalize(comp.targetPosition - entity.position) * speed

            // Apply boids forces only for schooling/peaceful fish that aren't feeding
            if !comp.isFeeding, comp.behaviorType == .schooling || comp.behaviorType == .peaceful {
                let boidsForce = computeBoids(entity: entity, comp: comp, allFish: allFish)
                steering += boidsForce
            }

            // 4. Wall repulsion to keep fish inside the tank
            if let b = bounds {
                steering += wallRepulsion(position: entity.position, bounds: b)
            }

            // 5. Depth preference — gently push fish toward preferred Y band
            if let b = bounds {
                let prefY = mix(b.floorY + b.halfExtents.y * comp.depthMin * 2,
                                b.ceilingY - b.halfExtents.y * (1 - comp.depthMax) * 2,
                                t: Float.random(in: 0...1))
                let depthForce = (prefY - entity.position.y) * 0.15
                steering.y += depthForce
            }

            // 6. Smooth velocity toward the steering direction
            let targetVel = simd_normalize(simd_length(steering) > 0.001 ? steering : comp.velocity) * speed
            let blend = comp.isFeeding ? min(dt * 4.0, 1.0) : min(dt * 2.5, 1.0)
            // Lerp toward the target velocity (scalar blend → vector result).
            comp.velocity += (targetVel - comp.velocity) * blend

            // 7. Integrate position
            var newPos = entity.position + comp.velocity * dt

            // Clamp within bounds
            if let b = bounds {
                newPos = simd_clamp(newPos, b.minBound, b.maxBound)
                newPos.y = simd_clamp(newPos.y, b.floorY, b.ceilingY)
            }
            entity.position = newPos

            // 8. Rotate fish to face swim direction with sinusoidal body roll
            if simd_length(comp.velocity) > 0.001 {
                let forward = simd_normalize(comp.velocity)
                let yaw = simd_quatf(from: SIMD3(0, 0, -1), to: forward)

                // Banking: lean into turns proportional to lateral velocity change
                let rollAngle = comp.aggressiveBanking ? sin(comp.swimPhase) * 0.15 : sin(comp.swimPhase) * 0.06
                let roll = simd_quatf(angle: rollAngle, axis: forward)
                entity.orientation = yaw * roll
            }

            entity.components[FishComponent.self] = comp
        }
    }

    // MARK: - Helpers

    private func randomTarget(comp: FishComponent, bounds: TankBoundsComponent?) -> SIMD3<Float> {
        let half = bounds?.halfExtents ?? SIMD3(0.3, 0.2, 0.2)
        let margin: Float = 0.06
        let x = Float.random(in: (-half.x + margin)...(half.x - margin))
        let yMin = bounds.map { $0.floorY + half.y * comp.depthMin } ?? -half.y + margin
        let yMax = bounds.map { $0.ceilingY - half.y * (1 - comp.depthMax) } ?? half.y - margin
        let y = Float.random(in: yMin...max(yMin + 0.01, yMax))
        let z = Float.random(in: (-half.z + margin)...(half.z - margin))
        return SIMD3(x, y, z)
    }

    private func computeBoids(
        entity: Entity,
        comp: FishComponent,
        allFish: [(entity: Entity, comp: FishComponent)]
    ) -> SIMD3<Float> {
        var cohesion    = SIMD3<Float>.zero
        var separation  = SIMD3<Float>.zero
        var alignment   = SIMD3<Float>.zero
        var neighborCount = 0

        for (other, otherComp) in allFish {
            guard other.id != entity.id else { continue }
            // Only apply boids within the same school group
            guard otherComp.schoolGroupID == comp.schoolGroupID else { continue }

            let diff = other.position - entity.position
            let dist = simd_length(diff)
            guard dist < Self.neighborRadius else { continue }

            neighborCount += 1
            cohesion += other.position

            if dist < Self.separationRadius, dist > 0.0001 {
                separation -= simd_normalize(diff) / dist
            }

            alignment += otherComp.velocity
        }

        guard neighborCount > 0 else { return .zero }

        let n = Float(neighborCount)
        let cohesionForce = ((cohesion / n) - entity.position) * Self.cohesionWeight
        let separationForce = separation * Self.separationWeight
        let alignmentForce  = (alignment / n) * Self.alignmentWeight

        return cohesionForce + separationForce + alignmentForce
    }

    private func wallRepulsion(position: SIMD3<Float>, bounds: TankBoundsComponent) -> SIMD3<Float> {
        let min = bounds.minBound
        let max = bounds.maxBound
        let k = Self.wallRepelStrength

        let fx = repelAxis(v: position.x, lo: min.x, hi: max.x, k: k)
        let fy = repelAxis(v: position.y, lo: bounds.floorY, hi: bounds.ceilingY, k: k)
        let fz = repelAxis(v: position.z, lo: min.z, hi: max.z, k: k)
        return SIMD3(fx, fy, fz)
    }

    private func repelAxis(v: Float, lo: Float, hi: Float, k: Float) -> Float {
        let zone: Float = 0.06
        if v - lo < zone { return k * (1 - (v - lo) / zone) }
        if hi - v < zone { return -k * (1 - (hi - v) / zone) }
        return 0
    }
}

// FishBehaviorType needs to be accessible in the system
private extension FishComponent {
    var aggressiveBanking: Bool {
        behaviorType == .schooling || behaviorType == .curious
    }
}

private func mix(_ a: Float, _ b: Float, t: Float) -> Float {
    a * (1 - t) + b * t
}
