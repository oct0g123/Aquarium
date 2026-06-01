import Foundation
import SwiftUI

enum TankTheme: String, CaseIterable, Codable, Identifiable {
    case tropical     = "Tropical"
    case saltwater    = "Saltwater Reef"
    case coldwater    = "Cold Freshwater"
    case zen          = "Japanese Zen"

    var id: String { rawValue }

    var waterColor: SIMD4<Float> {
        switch self {
        case .tropical:  return SIMD4(0.10, 0.50, 0.70, 0.55)
        case .saltwater: return SIMD4(0.05, 0.35, 0.80, 0.55)
        case .coldwater: return SIMD4(0.20, 0.60, 0.60, 0.50)
        case .zen:       return SIMD4(0.15, 0.45, 0.50, 0.48)
        }
    }

    var swiftUIColor: Color {
        let c = waterColor
        return Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z))
    }

    var description: String {
        switch self {
        case .tropical:  return "Warm, colorful freshwater with vibrant fish"
        case .saltwater: return "Ocean reef with corals and exotic marine life"
        case .coldwater: return "Clear mountain stream with trout and plants"
        case .zen:       return "Minimalist Japanese garden with koi and stones"
        }
    }

    var icon: String {
        switch self {
        case .tropical:  return "sun.max.fill"
        case .saltwater: return "water.waves"
        case .coldwater: return "snowflake"
        case .zen:       return "leaf.fill"
        }
    }
}

enum LightingMode: String, CaseIterable, Codable, Identifiable {
    case daylight        = "Daylight"
    case twilight        = "Twilight"
    case moonlight       = "Moonlight"
    case bioluminescent  = "Bioluminescent"

    var id: String { rawValue }

    var lightIntensity: Float {
        switch self {
        case .daylight:       return 1200
        case .twilight:       return 450
        case .moonlight:      return 80
        case .bioluminescent: return 300
        }
    }

    var lightColor: SIMD3<Float> {
        switch self {
        case .daylight:       return SIMD3(1.00, 0.98, 0.90)
        case .twilight:       return SIMD3(1.00, 0.75, 0.50)
        case .moonlight:      return SIMD3(0.70, 0.80, 1.00)
        case .bioluminescent: return SIMD3(0.30, 1.00, 0.80)
        }
    }

    var icon: String {
        switch self {
        case .daylight:       return "sun.max"
        case .twilight:       return "sunset.fill"
        case .moonlight:      return "moon.stars.fill"
        case .bioluminescent: return "sparkles"
        }
    }
}

enum SubstrateType: String, CaseIterable, Codable, Identifiable {
    case fineSand    = "Fine Sand"
    case gravelMix   = "Gravel Mix"
    case blackSand   = "Black Sand"
    case coralRubble = "Coral Rubble"
    case smoothPebble = "Smooth Pebbles"

    var id: String { rawValue }

    var color: SIMD4<Float> {
        switch self {
        case .fineSand:     return SIMD4(0.90, 0.85, 0.70, 1)
        case .gravelMix:    return SIMD4(0.60, 0.55, 0.50, 1)
        case .blackSand:    return SIMD4(0.10, 0.10, 0.12, 1)
        case .coralRubble:  return SIMD4(0.85, 0.80, 0.75, 1)
        case .smoothPebble: return SIMD4(0.65, 0.60, 0.55, 1)
        }
    }
}

enum TankSize: String, CaseIterable, Codable, Identifiable {
    case nano   = "Nano (20 L)"
    case small  = "Small (60 L)"
    case medium = "Medium (120 L)"
    case large  = "Large (200 L)"
    case xlarge = "XL Display (400 L)"

    var id: String { rawValue }

    // Interior usable dimensions in meters (width × height × depth)
    var dimensions: SIMD3<Float> {
        switch self {
        case .nano:   return SIMD3(0.35, 0.25, 0.22)
        case .small:  return SIMD3(0.50, 0.35, 0.30)
        case .medium: return SIMD3(0.65, 0.42, 0.38)
        case .large:  return SIMD3(0.80, 0.50, 0.45)
        case .xlarge: return SIMD3(1.00, 0.60, 0.50)
        }
    }

    var maxFishCount: Int {
        switch self {
        case .nano:   return 5
        case .small:  return 12
        case .medium: return 22
        case .large:  return 35
        case .xlarge: return 60
        }
    }
}

struct TankConfiguration: Codable, Equatable {
    var tankName: String    = "My Aquarium"
    var theme: TankTheme    = .tropical
    var lighting: LightingMode = .daylight
    var substrate: SubstrateType = .fineSand
    var tankSize: TankSize  = .medium
    var bubblesEnabled: Bool = true
    var plantsEnabled: Bool  = true
    var glowEnabled: Bool    = false
}
