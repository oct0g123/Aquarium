import SwiftUI
import RealityKit

@main
struct AquariumApp: App {
    @State private var appModel = AppModel()

    init() {
        // Register ECS types before any scene loads
        FishComponent.registerComponent()
        TankBoundsComponent.registerComponent()
        FishBehaviorSystem.registerSystem()
    }

    var body: some Scene {
        // Main hub window
        WindowGroup(id: "main") {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.plain)
        .defaultSize(width: 440, height: 600)

        // Volumetric tank window
        WindowGroup(id: "aquarium-volume") {
            AquariumVolumeView()
                .environment(appModel)
        }
        .windowStyle(.volumetric)
        .defaultSize(
            width:  Double(TankSize.medium.dimensions.x),
            height: Double(TankSize.medium.dimensions.y),
            depth:  Double(TankSize.medium.dimensions.z),
            in: .meters
        )

        // Full immersive dive mode
        ImmersiveSpace(id: "immersive-aquarium") {
            ImmersiveView()
                .environment(appModel)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
