import SwiftUI
import RealityKit

// Main entry window — shown before the volumetric tank is opened.
// Serves as the app home, tank summary, and launch pad.
struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    tankPreviewCard
                    fishSummarySection
                    quickActionsSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .navigationTitle(appModel.store.tankConfig.tankName)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appModel.catalogTab = .themes
                        appModel.showCatalog = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { appModel.showCatalog },
                set: { appModel.showCatalog = $0 }
            )) {
                CatalogSheet()
                    .environment(appModel)
            }
        }
        .frame(minWidth: 400, minHeight: 550)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 6) {
            Image(systemName: "fish.fill")
                .font(.system(size: 40))
                .foregroundStyle(appModel.store.tankConfig.theme.swiftUIColor)
                .symbolEffect(.pulse)   // .breathe requires visionOS 2.0; .pulse works on 1.0+
            Text("Virtual Aquarium")
                .font(.largeTitle.bold())
            Text("Your personal window into the deep")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var tankPreviewCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appModel.store.tankConfig.tankName)
                        .font(.headline)
                    Text(appModel.store.tankConfig.tankSize.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label(appModel.fishCountLabel, systemImage: "fish.fill")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        appModel.canAddMoreFish
                            ? Color.accentColor.opacity(0.15)
                            : Color.red.opacity(0.15),
                        in: Capsule()
                    )
            }

            // Water color preview strip
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            appModel.store.tankConfig.theme.swiftUIColor.opacity(0.6),
                            appModel.store.tankConfig.theme.swiftUIColor
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 80)
                .overlay(
                    HStack(spacing: 8) {
                        ForEach(topFishEmoji, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title2)
                        }
                    }
                )

            // Open tank button
            Button {
                openWindow(id: "aquarium-volume")
            } label: {
                Label("Open Tank", systemImage: "play.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            // Immersive dive button
            Button {
                Task {
                    if appModel.immersiveSpaceState == .open {
                        await dismissImmersiveSpace()
                        appModel.immersiveSpaceState = .closed
                    } else {
                        appModel.immersiveSpaceState = .transitioning
                        switch await openImmersiveSpace(id: "immersive-aquarium") {
                        case .opened:
                            appModel.immersiveSpaceState = .open
                        default:
                            appModel.immersiveSpaceState = .closed
                        }
                    }
                }
            } label: {
                Label(
                    appModel.immersiveSpaceState == .open ? "Exit Dive Mode" : "Dive In",
                    systemImage: appModel.immersiveSpaceState == .open ? "xmark.circle.fill" : "water.waves"
                )
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(appModel.immersiveSpaceState == .transitioning)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var fishSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Fish")
                    .font(.title3.bold())
                Spacer()
                Button("Add more") {
                    appModel.catalogTab = .fish
                    appModel.showCatalog = true
                }
                .font(.subheadline)
            }

            if appModel.store.fish.isEmpty {
                ContentUnavailableView(
                    "No fish yet",
                    systemImage: "fish",
                    description: Text("Tap \"Add more\" to stock your tank")
                )
                .frame(height: 100)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(groupedFish, id: \.key) { entry in
                        fishGroupBadge(speciesID: entry.key, count: entry.value)
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Customize")
                .font(.title3.bold())

            HStack(spacing: 12) {
                quickActionButton(icon: appModel.store.tankConfig.theme.icon,
                                  label: appModel.store.tankConfig.theme.rawValue,
                                  tint: appModel.store.tankConfig.theme.swiftUIColor) {
                    appModel.catalogTab = .themes
                    appModel.showCatalog = true
                }
                quickActionButton(icon: appModel.store.tankConfig.lighting.icon,
                                  label: appModel.store.tankConfig.lighting.rawValue,
                                  tint: Color(red: 1, green: 0.85, blue: 0.4)) {
                    appModel.catalogTab = .themes
                    appModel.showCatalog = true
                }
                quickActionButton(icon: "leaf.fill",
                                  label: "Decor",
                                  tint: .green) {
                    appModel.catalogTab = .decorations
                    appModel.showCatalog = true
                }
            }
        }
    }

    // MARK: - Helpers

    private var topFishEmoji: [String] {
        let unique = Array(Set(appModel.store.fish.compactMap { $0.species?.emoji }))
        return Array(unique.prefix(6))
    }

    private var groupedFish: [(key: String, value: Int)] {
        var groups: [String: Int] = [:]
        for fish in appModel.store.fish {
            groups[fish.speciesID, default: 0] += 1
        }
        return groups.sorted { $0.value > $1.value }
    }

    @ViewBuilder
    private func fishGroupBadge(speciesID: String, count: Int) -> some View {
        if let species = FishSpecies.catalog.first(where: { $0.id == speciesID }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Text(species.emoji)
                        .font(.title)
                    if count > 1 {
                        Text("\(count)")
                            .font(.caption2.bold())
                            .padding(3)
                            .background(Color.accentColor, in: Circle())
                            .foregroundStyle(.white)
                            .offset(x: 6, y: -6)
                    }
                }
                Text(species.commonName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .padding(10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private func quickActionButton(icon: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                Text(label)
                    .font(.caption2.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
    }
}
