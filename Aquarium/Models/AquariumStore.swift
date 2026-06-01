import Foundation
import SwiftUI

// Represents a fish that has been added to the tank
struct FishInstance: Identifiable, Codable, Equatable {
    let id: UUID
    let speciesID: String
    var nickname: String?
    let dateAdded: Date

    init(speciesID: String, nickname: String? = nil) {
        self.id = UUID()
        self.speciesID = speciesID
        self.nickname = nickname
        self.dateAdded = .now
    }

    var species: FishSpecies? {
        FishSpecies.catalog.first { $0.id == speciesID }
    }

    var displayName: String {
        nickname ?? species?.commonName ?? speciesID
    }
}

// Codable SIMD3 wrapper for persisting decoration positions
struct CodableVector3: Codable, Equatable {
    var x: Float; var y: Float; var z: Float
    init(_ v: SIMD3<Float>) { x = v.x; y = v.y; z = v.z }
    var simd: SIMD3<Float> { SIMD3(x, y, z) }
}

// Represents a decoration placed inside the tank
struct DecorationInstance: Identifiable, Codable, Equatable {
    let id: UUID
    let itemID: String
    var position: CodableVector3
    var yRotation: Float   // radians
    var scale: Float

    init(itemID: String, position: SIMD3<Float>, yRotation: Float = 0, scale: Float = 1) {
        self.id = UUID()
        self.itemID = itemID
        self.position = CodableVector3(position)
        self.yRotation = yRotation
        self.scale = scale
    }

    var item: DecorationItem? {
        DecorationItem.catalog.first { $0.id == itemID }
    }
}

// Serializable snapshot of the full aquarium state
struct AquariumSave: Codable {
    var tankConfig: TankConfiguration
    var fish: [FishInstance]
    var decorations: [DecorationInstance]
}

// MARK: - AquariumStore
@Observable
final class AquariumStore {
    var tankConfig: TankConfiguration = .init()
    var fish: [FishInstance] = []
    var decorations: [DecorationInstance] = []

    private let saveKey = "aquarium_save_v1"

    init() { load() }

    // MARK: Fish
    func addFish(speciesID: String) {
        guard fish.count < tankConfig.tankSize.maxFishCount else { return }
        fish.append(FishInstance(speciesID: speciesID))
        save()
    }

    func removeFish(_ instance: FishInstance) {
        fish.removeAll { $0.id == instance.id }
        save()
    }

    func removeAllFish() {
        fish.removeAll()
        save()
    }

    // MARK: Decorations
    func addDecoration(itemID: String, position: SIMD3<Float>, yRotation: Float = 0, scale: Float = 1) {
        let inst = DecorationInstance(itemID: itemID, position: position, yRotation: yRotation, scale: scale)
        decorations.append(inst)
        save()
    }

    func updateDecoration(_ id: UUID, position: SIMD3<Float>) {
        if let idx = decorations.firstIndex(where: { $0.id == id }) {
            decorations[idx].position = CodableVector3(position)
            save()
        }
    }

    func removeDecoration(_ id: UUID) {
        decorations.removeAll { $0.id == id }
        save()
    }

    // MARK: Tank Config
    func applyConfig(_ newConfig: TankConfiguration) {
        tankConfig = newConfig
        save()
    }

    // MARK: Persistence
    func save() {
        let snapshot = AquariumSave(tankConfig: tankConfig, fish: fish, decorations: decorations)
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let snapshot = try? JSONDecoder().decode(AquariumSave.self, from: data) else {
            seedDefaults()
            return
        }
        tankConfig = snapshot.tankConfig
        fish = snapshot.fish
        decorations = snapshot.decorations
    }

    private func seedDefaults() {
        // Give a fresh install a few fish to start with
        fish = [
            FishInstance(speciesID: "clownfish"),
            FishInstance(speciesID: "clownfish"),
            FishInstance(speciesID: "neon_tetra"),
            FishInstance(speciesID: "neon_tetra"),
            FishInstance(speciesID: "neon_tetra"),
            FishInstance(speciesID: "blue_tang"),
        ]
        save()
    }
}
