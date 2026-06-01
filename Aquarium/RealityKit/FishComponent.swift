import RealityKit
import Foundation

// ECS component attached to every fish entity in the scene
struct FishComponent: Component, Codable {
    static let query = EntityQuery(where: .has(FishComponent.self))

    var speciesID: String
    var instanceID: UUID

    // Kinematics
    var velocity: SIMD3<Float> = .zero
    var targetPosition: SIMD3<Float> = .zero

    // Swimming animation state
    var swimPhase: Float = 0         // drives sinusoidal body oscillation
    var swimSpeed: Float = 0.08      // base speed (meters/sec)

    // Behavior state
    var behaviorType: FishBehaviorType = .peaceful
    var wanderTimer: Float = 0       // time until next wander target
    var preferredSchoolSize: Int = 1

    // Depth preference encoded as normalized Y range [0, 1] within tank
    var depthMin: Float = 0.2
    var depthMax: Float = 0.8

    // Which "school group" this fish belongs to (same speciesID → same group)
    var schoolGroupID: String { speciesID }
}

// Thin wrapper placed on the tank root entity so the behavior system
// can read tank bounds without searching the scene graph.
struct TankBoundsComponent: Component {
    var halfExtents: SIMD3<Float>   // half of the interior usable dimensions
    var wallThickness: Float = 0.004

    var minBound: SIMD3<Float> { -halfExtents + wallThickness }
    var maxBound: SIMD3<Float> {  halfExtents - wallThickness }

    // Keep fish a little away from the substrate
    var floorY: Float { -halfExtents.y + 0.03 }
    var ceilingY: Float { halfExtents.y - 0.03 }
}
