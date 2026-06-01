import RealityKit
import Foundation

// MARK: - Bubble Emitter
// Builds RealityKit ParticleEmitterComponent entities that produce streams of
// rising bubbles. Used both for the tank's ambient bubbler and for the
// "bubble_wand" novelty decoration.

enum BubbleEmitter {

    /// A vertical column of bubbles rising from a point.
    static func makeColumn(height: Float = 0.3, intensity: Float = 1.0) -> Entity {
        let entity = Entity()
        entity.name = "bubble_emitter"

        var particles = ParticleEmitterComponent()
        particles.emitterShape = .sphere
        particles.emitterShapeSize = SIMD3(0.01, 0.005, 0.01)
        particles.birthLocation = .volume
        particles.birthDirection = .local

        particles.mainEmitter.birthRate = 18 * intensity
        particles.mainEmitter.lifeSpan = Double(height / 0.06)   // live long enough to reach the top
        particles.mainEmitter.size = 0.004
        particles.mainEmitter.sizeVariation = 0.003

        // Rise upward with slight spread
        particles.mainEmitter.acceleration = SIMD3(0, 0.04, 0)
        particles.speed = 0.06
        particles.speedVariation = 0.02
        particles.emissionDirection = SIMD3(0, 1, 0)

        // Bubble appearance — bright, semi-transparent, fading
        particles.mainEmitter.color = .evolving(
            start: .single(.init(red: 0.85, green: 0.92, blue: 1.0, alpha: 0.55)),
            end:   .single(.init(red: 0.85, green: 0.92, blue: 1.0, alpha: 0.0))
        )
        particles.mainEmitter.opacityCurve = .quickFadeInOut
        particles.mainEmitter.sizeMultiplierAtEndOfLifespan = 1.6

        entity.components.set(particles)
        return entity
    }

    /// A wide, gentle scattering of bubbles across the tank surface.
    static func makeAmbient(tankDims: SIMD3<Float>) -> Entity {
        let entity = Entity()
        entity.name = "ambient_bubbles"

        var particles = ParticleEmitterComponent()
        particles.emitterShape = .box
        particles.emitterShapeSize = SIMD3(tankDims.x * 0.8, 0.01, tankDims.z * 0.8)
        particles.birthLocation = .volume

        particles.mainEmitter.birthRate = 6
        particles.mainEmitter.lifeSpan = Double(tankDims.y / 0.04)
        particles.mainEmitter.size = 0.003
        particles.mainEmitter.sizeVariation = 0.002
        particles.mainEmitter.acceleration = SIMD3(0, 0.03, 0)
        particles.speed = 0.04
        particles.speedVariation = 0.015
        particles.emissionDirection = SIMD3(0, 1, 0)

        particles.mainEmitter.color = .evolving(
            start: .single(.init(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.35)),
            end:   .single(.init(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.0))
        )
        particles.mainEmitter.opacityCurve = .quickFadeInOut

        entity.components.set(particles)
        // Sit at the substrate, centered
        entity.position = SIMD3(0, -tankDims.y / 2 + 0.02, 0)
        return entity
    }
}
