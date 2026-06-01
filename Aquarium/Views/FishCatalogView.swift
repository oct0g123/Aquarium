import SwiftUI

struct FishCatalogView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedSpecies: FishSpecies? = nil
    @State private var filterTheme: TankTheme? = nil

    private var displayedSpecies: [FishSpecies] {
        if let theme = filterTheme {
            return FishSpecies.catalog.filter { $0.compatibleThemes.contains(theme) }
        }
        return FishSpecies.catalog
    }

    var body: some View {
        VStack(spacing: 0) {
            // Theme filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    themeFilterPill(nil, label: "All")
                    ForEach(TankTheme.allCases) { theme in
                        themeFilterPill(theme, label: theme.rawValue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(.bar)

            // Capacity indicator
            HStack {
                Label(appModel.fishCountLabel, systemImage: "fish.fill")
                    .font(.caption)
                    .foregroundStyle(appModel.canAddMoreFish ? .secondary : .red)
                Spacer()
                if !appModel.canAddMoreFish {
                    Text("Tank is full — upgrade size in Theme tab")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.regularMaterial)

            // Fish grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200))], spacing: 12) {
                    ForEach(displayedSpecies) { species in
                        FishCard(species: species, isSelected: selectedSpecies?.id == species.id) {
                            selectedSpecies = selectedSpecies?.id == species.id ? nil : species
                        }
                    }
                }
                .padding(16)
            }
        }
        .sheet(item: $selectedSpecies) { species in
            FishDetailSheet(species: species)
                .environment(appModel)
        }
    }

    @ViewBuilder
    private func themeFilterPill(_ theme: TankTheme?, label: String) -> some View {
        Button {
            filterTheme = theme
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(filterTheme == theme ? Color.accentColor : Color.secondary.opacity(0.15),
                            in: Capsule())
                .foregroundStyle(filterTheme == theme ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Fish Card
struct FishCard: View {
    let species: FishSpecies
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(species.bodyColor.color.opacity(0.18))
                    Text(species.emoji)
                        .font(.system(size: 44))
                }
                .frame(height: 80)

                VStack(alignment: .leading, spacing: 2) {
                    Text(species.commonName)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Text(species.scientificName)
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Label(species.temperamentLabel, systemImage: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(temperamentColor(species.temperamentLabel))
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
    }

    private func temperamentColor(_ label: String) -> Color {
        switch label {
        case "Peaceful": return .green
        case "Semi-aggressive": return .orange
        case "Aggressive": return .red
        default: return .secondary
        }
    }
}

// MARK: - Fish Detail Sheet
struct FishDetailSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    let species: FishSpecies

    // How many of this species are already in the tank
    private var currentCount: Int {
        appModel.store.fish.filter { $0.speciesID == species.id }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero
                    ZStack {
                        species.bodyColor.color.opacity(0.2)
                        Text(species.emoji)
                            .font(.system(size: 80))
                    }
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Description
                    Text(species.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statCell("Origin", value: species.originRegion, icon: "globe")
                        statCell("Diet", value: species.dietType, icon: "fork.knife")
                        statCell("Behavior", value: species.behavior.displayName, icon: "figure.run")
                        statCell("Temperament", value: species.temperamentLabel, icon: "heart.fill")
                        statCell("Swim Depth", value: species.swimmingDepth.displayName, icon: "water.waves")
                        statCell("In your tank", value: "\(currentCount)", icon: "fish.fill")
                    }
                    .padding(.horizontal)

                    // Compatible themes
                    if !species.compatibleThemes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Best in")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            HStack {
                                ForEach(species.compatibleThemes) { theme in
                                    Label(theme.rawValue, systemImage: theme.icon)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(theme.swiftUIColor.opacity(0.2), in: Capsule())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }

                    // Add button
                    Button {
                        appModel.store.addFish(speciesID: species.id)
                        dismiss()
                    } label: {
                        Label("Add to Tank", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(appModel.canAddMoreFish ? Color.accentColor : Color.secondary,
                                        in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                    .disabled(!appModel.canAddMoreFish)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(species.commonName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .frame(minWidth: 380, minHeight: 500)
    }

    @ViewBuilder
    private func statCell(_ title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Display name helpers
private extension FishBehaviorType {
    var displayName: String {
        switch self {
        case .schooling:   return "Schooling"
        case .solitary:    return "Solitary"
        case .territorial: return "Territorial"
        case .curious:     return "Curious"
        case .shy:         return "Shy"
        case .peaceful:    return "Peaceful"
        case .drifting:    return "Drifting"
        }
    }
}

private extension SwimmingDepth {
    var displayName: String {
        switch self {
        case .surface:  return "Surface"
        case .midwater: return "Mid-water"
        case .bottom:   return "Bottom"
        case .all:      return "All depths"
        }
    }
}
