import SwiftUI

struct DecorationCatalogView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedCategory: DecorationCategory = .plants
    @State private var selectedItem: DecorationItem? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Category picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DecorationCategory.allCases) { cat in
                        categoryPill(cat)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(.bar)

            // Items grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 190))], spacing: 12) {
                    ForEach(DecorationItem.items(for: selectedCategory)) { item in
                        DecorationCard(item: item, isSelected: selectedItem?.id == item.id) {
                            selectedItem = selectedItem?.id == item.id ? nil : item
                        }
                    }
                }
                .padding(16)
            }
        }
        .sheet(item: $selectedItem) { item in
            DecorationDetailSheet(item: item)
                .environment(appModel)
        }
    }

    @ViewBuilder
    private func categoryPill(_ category: DecorationCategory) -> some View {
        Button {
            selectedCategory = category
        } label: {
            Label(category.rawValue, systemImage: category.icon)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? Color.accentColor : Color.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(selectedCategory == category ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Decoration Card
struct DecorationCard: View {
    let item: DecorationItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.primaryColor.color.opacity(0.20))
                    Text(item.emoji)
                        .font(.system(size: 42))
                }
                .frame(height: 76)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Text(item.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
}

// MARK: - Decoration Detail Sheet
struct DecorationDetailSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    let item: DecorationItem

    @State private var chosenScale: Float = 1.0

    private var inTankCount: Int {
        appModel.store.decorations.filter { $0.itemID == item.id }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero
                    ZStack {
                        item.primaryColor.color.opacity(0.2)
                        Text(item.emoji)
                            .font(.system(size: 76))
                    }
                    .frame(height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    Text(item.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Size slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Size")
                                .font(.subheadline.bold())
                            Spacer()
                            Text(scaleLabelText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(chosenScale) },
                                set: { chosenScale = Float($0) }
                            ),
                            in: Double(item.minScale)...Double(item.maxScale)
                        )
                    }
                    .padding(.horizontal)

                    // Stats
                    if !item.compatibleThemes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Best in")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            HStack {
                                ForEach(item.compatibleThemes) { theme in
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

                    // Already in tank
                    if inTankCount > 0 {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("\(inTankCount) already in your tank")
                                .font(.caption)
                        }
                    }

                    // Add button
                    Button {
                        // Place at a random position on the substrate
                        let dims = appModel.store.tankConfig.tankSize.dimensions
                        let pos = SIMD3<Float>(
                            Float.random(in: -(dims.x * 0.35)...(dims.x * 0.35)),
                            -dims.y / 2 + item.footprint.y * chosenScale * 0.5 + 0.018,
                            Float.random(in: -(dims.z * 0.35)...(dims.z * 0.35))
                        )
                        appModel.store.addDecoration(
                            itemID: item.id,
                            position: pos,
                            yRotation: Float.random(in: 0...(.pi * 2)),
                            scale: chosenScale
                        )
                        dismiss()
                    } label: {
                        Label("Add to Tank", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                chosenScale = (item.minScale + item.maxScale) / 2
            }
        }
        .frame(minWidth: 380, minHeight: 460)
    }

    private var scaleLabelText: String {
        let pct = Int(((chosenScale - item.minScale) / (item.maxScale - item.minScale)) * 100)
        if pct < 30 { return "Small" }
        if pct < 65 { return "Medium" }
        return "Large"
    }
}
