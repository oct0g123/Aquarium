import RealityKit
import Foundation
import AVFoundation

// MARK: - Aquarium Audio
// Manages spatial ambient audio for the tank. Generates a soft underwater
// bubbling/hum bed procedurally so the app ships without bundled audio files;
// if an "ambience.wav" resource is added to the bundle it is preferred.
//
// Audio is attached to an entity in the scene so visionOS spatializes it —
// the sound appears to emanate from the tank itself.

enum AquariumAudio {

    /// Attaches a looping spatial ambience to the given entity.
    static func attachAmbience(to entity: Entity, volume: Float = 0.4) {
        // Prefer a bundled audio file if present.
        if let resource = try? AudioFileResource.load(
            named: "ambience.wav",
            configuration: .init(shouldLoop: true)
        ) {
            configureSpatial(entity)
            let controller = entity.playAudio(resource)
            controller.gain = gain(forLinear: volume)
            return
        }

        // Otherwise synthesize a gentle underwater bed and loop it.
        guard let resource = synthesizeAmbience() else { return }
        configureSpatial(entity)
        let controller = entity.playAudio(resource)
        controller.gain = gain(forLinear: volume)
    }

    /// Plays a short non-looping bubble "blip" — used for feeding feedback.
    static func playFeedBlip(on entity: Entity) {
        guard let resource = synthesizeBlip() else { return }
        let controller = entity.playAudio(resource)
        controller.gain = gain(forLinear: 0.6)
    }

    // MARK: - Spatialization

    private static func configureSpatial(_ entity: Entity) {
        var spatial = SpatialAudioComponent()
        spatial.directivity = .beam(focus: 0.2)   // gently directional, mostly omni
        entity.components.set(spatial)
    }

    private static func gain(forLinear volume: Float) -> Audio.Decibel {
        // Convert a 0...1 linear volume into decibels (0 dB = full).
        let clamped = max(0.0001, min(1, volume))
        return Audio.Decibel(20 * log10(clamped))
    }

    // MARK: - Procedural Audio Generation

    /// Generates ~6s of layered low bubbling + water hum, suitable for looping.
    private static func synthesizeAmbience() -> AudioFileResource? {
        let sampleRate = 44_100.0
        let duration = 6.0
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        var rng = SystemRandomNumberGenerator()

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            // Low water hum: two detuned sines
            let hum = 0.06 * sin(2 * .pi * 90 * t) + 0.04 * sin(2 * .pi * 134 * t)
            // Slow amplitude swell
            let swell = 0.5 + 0.5 * sin(2 * .pi * 0.1 * t)
            // Sparse bubble pops: random short decaying chirps
            var bubble = 0.0
            if Double.random(in: 0...1, using: &rng) < 0.0008 {
                bubble = 0.12
            }
            samples[i] = Float((hum * swell) + bubble * sin(2 * .pi * 600 * t))
        }

        // Smooth the loop boundary with a short crossfade
        let fade = Int(sampleRate * 0.1)
        for i in 0..<fade {
            let g = Float(i) / Float(fade)
            samples[i] *= g
            samples[frameCount - 1 - i] *= g
        }

        return makeResource(from: samples, sampleRate: sampleRate, loop: true)
    }

    /// Generates a short rising bubble blip.
    private static func synthesizeBlip() -> AudioFileResource? {
        let sampleRate = 44_100.0
        let duration = 0.35
        let frameCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: frameCount)

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let progress = t / duration
            // Rising pitch, decaying amplitude
            let freq = 400 + 500 * progress
            let env = exp(-6 * progress)
            samples[i] = Float(0.3 * env * sin(2 * .pi * freq * t))
        }

        return makeResource(from: samples, sampleRate: sampleRate, loop: false)
    }

    // MARK: - PCM → AudioFileResource

    private static func makeResource(from samples: [Float], sampleRate: Double, loop: Bool) -> AudioFileResource? {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: sampleRate,
                                         channels: 1,
                                         interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(samples.count)) else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let channel = buffer.floatChannelData?[0] {
            samples.withUnsafeBufferPointer { ptr in
                channel.update(from: ptr.baseAddress!, count: samples.count)
            }
        }

        // Write to a temporary file, then load as an AudioFileResource.
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("aq_\(loop ? "amb" : "blip")_\(UUID().uuidString).caf")
        do {
            let file = try AVAudioFile(forWriting: url,
                                       settings: format.settings,
                                       commonFormat: .pcmFormatFloat32,
                                       interleaved: false)
            try file.write(from: buffer)
            return try AudioFileResource.load(
                contentsOf: url,
                configuration: .init(shouldLoop: loop)
            )
        } catch {
            return nil
        }
    }
}
