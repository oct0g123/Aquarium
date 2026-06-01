import Foundation
import SwiftUI

enum SwimmingDepth: String, Codable {
    case surface, midwater, bottom, all
}

enum FishBehaviorType: String, Codable {
    case schooling   // stays in groups, follows nearest school-mate
    case solitary    // avoids others of same species
    case territorial // drifts to a home zone, chases intruders
    case curious     // gradually approaches the viewer position
    case shy         // moves away from viewer
    case peaceful    // slow, relaxed random wander
    case drifting    // very slow, passive (jellyfish-style)
}

// Codable wrapper so colors can be persisted in FishInstance
struct CodableColor: Codable, Equatable, Hashable {
    let r: Float; let g: Float; let b: Float

    init(_ r: Float, _ g: Float, _ b: Float) { self.r = r; self.g = g; self.b = b }

    var simd4: SIMD4<Float> { SIMD4(r, g, b, 1) }
    var color: Color { Color(red: Double(r), green: Double(g), blue: Double(b)) }
}

struct FishSpecies: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let commonName: String
    let scientificName: String
    let description: String

    // Physical properties
    let bodyLength: Float      // approximate body length in meters
    let baseSwimSpeed: Float   // meters per second
    let preferredSchoolSize: Int  // 1 = solitary
    let swimmingDepth: SwimmingDepth
    let behavior: FishBehaviorType

    // Appearance (used to drive procedural mesh coloring)
    let bodyColor: CodableColor
    let finColor: CodableColor
    let accentColor: CodableColor

    // Tank compatibility
    let compatibleThemes: [TankTheme]

    // Info card metadata
    let originRegion: String
    let dietType: String
    let temperamentLabel: String
    let emoji: String

    // Fish whose bodies should pulse/oscillate (jellyfish etc.)
    var usesPulseAnimation: Bool { behavior == .drifting }
    // Fish that should tilt more dramatically on turns
    var aggressiveBanking: Bool { behavior == .schooling || behavior == .curious }
}

// MARK: - Fish Catalog
extension FishSpecies {
    static let catalog: [FishSpecies] = [
        .init(
            id: "clownfish",
            commonName: "Clownfish",
            scientificName: "Amphiprion ocellaris",
            description: "Iconic orange-and-white reef fish. Curious and spirited, they investigate everything in the tank.",
            bodyLength: 0.08, baseSwimSpeed: 0.09, preferredSchoolSize: 2,
            swimmingDepth: .midwater, behavior: .curious,
            bodyColor: CodableColor(0.95, 0.50, 0.04),
            finColor:  CodableColor(1.00, 0.62, 0.08),
            accentColor: CodableColor(1.0, 1.0, 1.0),
            compatibleThemes: [.saltwater],
            originRegion: "Indo-Pacific", dietType: "Omnivore",
            temperamentLabel: "Peaceful", emoji: "🐠"
        ),
        .init(
            id: "betta",
            commonName: "Betta",
            scientificName: "Betta splendens",
            description: "Flowing finnage and jewel-like colors. Males are solitary kings who drift with regal slowness.",
            bodyLength: 0.07, baseSwimSpeed: 0.05, preferredSchoolSize: 1,
            swimmingDepth: .midwater, behavior: .territorial,
            bodyColor: CodableColor(0.25, 0.18, 0.88),
            finColor:  CodableColor(0.55, 0.08, 0.92),
            accentColor: CodableColor(0.90, 0.38, 0.10),
            compatibleThemes: [.tropical, .zen],
            originRegion: "Southeast Asia", dietType: "Carnivore",
            temperamentLabel: "Aggressive", emoji: "🐡"
        ),
        .init(
            id: "neon_tetra",
            commonName: "Neon Tetra",
            scientificName: "Paracheirodon innesi",
            description: "Electric-blue flash with a vivid red tail stripe. Spectacular in large schools that move as one.",
            bodyLength: 0.04, baseSwimSpeed: 0.13, preferredSchoolSize: 8,
            swimmingDepth: .midwater, behavior: .schooling,
            bodyColor: CodableColor(0.05, 0.62, 0.92),
            finColor:  CodableColor(0.05, 0.72, 1.00),
            accentColor: CodableColor(0.92, 0.10, 0.10),
            compatibleThemes: [.tropical],
            originRegion: "Amazon Basin", dietType: "Omnivore",
            temperamentLabel: "Peaceful", emoji: "✨"
        ),
        .init(
            id: "angelfish",
            commonName: "Angelfish",
            scientificName: "Pterophyllum scalare",
            description: "Majestic disc-shaped cichlid with elongated finnage. Glides through mid-water with quiet authority.",
            bodyLength: 0.13, baseSwimSpeed: 0.06, preferredSchoolSize: 4,
            swimmingDepth: .midwater, behavior: .peaceful,
            bodyColor: CodableColor(0.85, 0.82, 0.75),
            finColor:  CodableColor(0.75, 0.72, 0.65),
            accentColor: CodableColor(0.28, 0.28, 0.28),
            compatibleThemes: [.tropical],
            originRegion: "Amazon River", dietType: "Omnivore",
            temperamentLabel: "Semi-aggressive", emoji: "🪽"
        ),
        .init(
            id: "koi",
            commonName: "Koi",
            scientificName: "Cyprinus rubrofuscus",
            description: "Noble, large-bodied fish with distinctive orange-and-white patterning. Symbols of good fortune.",
            bodyLength: 0.28, baseSwimSpeed: 0.07, preferredSchoolSize: 3,
            swimmingDepth: .midwater, behavior: .peaceful,
            bodyColor: CodableColor(1.00, 0.60, 0.10),
            finColor:  CodableColor(0.95, 0.50, 0.05),
            accentColor: CodableColor(1.00, 1.00, 1.00),
            compatibleThemes: [.zen, .coldwater],
            originRegion: "East Asia", dietType: "Omnivore",
            temperamentLabel: "Peaceful", emoji: "🎏"
        ),
        .init(
            id: "blue_tang",
            commonName: "Blue Tang",
            scientificName: "Paracanthurus hepatus",
            description: "Vivid royal-blue fish with a yellow tail brush. Energetic, loves open water.",
            bodyLength: 0.15, baseSwimSpeed: 0.11, preferredSchoolSize: 1,
            swimmingDepth: .midwater, behavior: .curious,
            bodyColor: CodableColor(0.10, 0.40, 0.92),
            finColor:  CodableColor(0.05, 0.30, 0.88),
            accentColor: CodableColor(1.00, 0.85, 0.00),
            compatibleThemes: [.saltwater],
            originRegion: "Indo-Pacific", dietType: "Herbivore",
            temperamentLabel: "Semi-aggressive", emoji: "💙"
        ),
        .init(
            id: "lionfish",
            commonName: "Lionfish",
            scientificName: "Pterois volitans",
            description: "Dramatic, venomous reef predator with flowing fan-like spines. Moves in a slow, mesmerizing hover.",
            bodyLength: 0.22, baseSwimSpeed: 0.04, preferredSchoolSize: 1,
            swimmingDepth: .midwater, behavior: .territorial,
            bodyColor: CodableColor(0.85, 0.20, 0.15),
            finColor:  CodableColor(0.90, 0.25, 0.10),
            accentColor: CodableColor(1.00, 1.00, 1.00),
            compatibleThemes: [.saltwater],
            originRegion: "Indo-Pacific", dietType: "Carnivore",
            temperamentLabel: "Aggressive", emoji: "🦁"
        ),
        .init(
            id: "goldfish",
            commonName: "Fancy Goldfish",
            scientificName: "Carassius auratus",
            description: "Round-bodied goldfish with flowing double-tail. Classic, cheerful, and endlessly watchable.",
            bodyLength: 0.12, baseSwimSpeed: 0.05, preferredSchoolSize: 2,
            swimmingDepth: .midwater, behavior: .peaceful,
            bodyColor: CodableColor(1.00, 0.60, 0.00),
            finColor:  CodableColor(1.00, 0.70, 0.10),
            accentColor: CodableColor(1.00, 0.90, 0.30),
            compatibleThemes: [.coldwater, .zen],
            originRegion: "East Asia", dietType: "Omnivore",
            temperamentLabel: "Peaceful", emoji: "🟠"
        ),
        .init(
            id: "moon_jellyfish",
            commonName: "Moon Jellyfish",
            scientificName: "Aurelia aurita",
            description: "Translucent, ethereal drifter. Pulsing bell and trailing tentacles create a hypnotic atmosphere.",
            bodyLength: 0.18, baseSwimSpeed: 0.025, preferredSchoolSize: 6,
            swimmingDepth: .all, behavior: .drifting,
            bodyColor: CodableColor(0.88, 0.93, 1.00),
            finColor:  CodableColor(0.68, 0.82, 0.95),
            accentColor: CodableColor(0.45, 0.68, 0.90),
            compatibleThemes: [.saltwater],
            originRegion: "Worldwide Oceans", dietType: "Filter Feeder",
            temperamentLabel: "Peaceful", emoji: "🪼"
        ),
        .init(
            id: "cory",
            commonName: "Corydoras",
            scientificName: "Corydoras paleatus",
            description: "Armored, whiskered catfish that bustle across the substrate. Peaceful tank cleaners in cheerful schools.",
            bodyLength: 0.06, baseSwimSpeed: 0.09, preferredSchoolSize: 6,
            swimmingDepth: .bottom, behavior: .schooling,
            bodyColor: CodableColor(0.62, 0.58, 0.48),
            finColor:  CodableColor(0.52, 0.48, 0.38),
            accentColor: CodableColor(0.28, 0.25, 0.20),
            compatibleThemes: [.tropical, .coldwater],
            originRegion: "South America", dietType: "Omnivore",
            temperamentLabel: "Peaceful", emoji: "🪸"
        ),
        .init(
            id: "discus",
            commonName: "Discus",
            scientificName: "Symphysodon discus",
            description: "The 'king of the aquarium'. Perfectly disc-shaped with vivid turquoise striping on a deep red body.",
            bodyLength: 0.18, baseSwimSpeed: 0.055, preferredSchoolSize: 5,
            swimmingDepth: .midwater, behavior: .schooling,
            bodyColor: CodableColor(0.70, 0.15, 0.10),
            finColor:  CodableColor(0.60, 0.10, 0.08),
            accentColor: CodableColor(0.10, 0.75, 0.80),
            compatibleThemes: [.tropical],
            originRegion: "Amazon River", dietType: "Omnivore",
            temperamentLabel: "Peaceful", emoji: "🔵"
        ),
        .init(
            id: "mandarin",
            commonName: "Mandarin Dragonet",
            scientificName: "Synchiropus splendidus",
            description: "One of the most vivid fish on the reef. Psychedelic swirls of blue, orange, and green.",
            bodyLength: 0.06, baseSwimSpeed: 0.04, preferredSchoolSize: 2,
            swimmingDepth: .bottom, behavior: .shy,
            bodyColor: CodableColor(0.10, 0.55, 0.90),
            finColor:  CodableColor(0.05, 0.45, 0.80),
            accentColor: CodableColor(1.00, 0.55, 0.00),
            compatibleThemes: [.saltwater],
            originRegion: "Western Pacific", dietType: "Carnivore",
            temperamentLabel: "Peaceful", emoji: "🌈"
        )
    ]
}
