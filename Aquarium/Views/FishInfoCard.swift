import SwiftUI

// Compact info card shown floating beside a fish when tapped in the tank.
// Rendered as a RealityView attachment so it lives in 3D space next to the fish.
struct FishInfoCard: View {
    let species: FishSpecies
    let nickname: String?
    let onRemove: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(species.emoji)
                    .font(.system(size: 34))
                VStack(alignment: .leading, spacing: 1) {
                    Text(nickname ?? species.commonName)
                        .font(.headline)
                    Text(species.scientificName)
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text(species.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack(spacing: 6) {
                infoChip(species.originRegion, icon: "globe")
                infoChip(species.dietType, icon: "fork.knife")
            }
            HStack(spacing: 6) {
                infoChip(species.temperamentLabel, icon: "heart.fill")
                infoChip(swimDepthLabel, icon: "water.waves")
            }

            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove from tank", systemImage: "trash")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.top, 2)
        }
        .padding(14)
        .frame(width: 260)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 8)
    }

    private var swimDepthLabel: String {
        switch species.swimmingDepth {
        case .surface:  return "Surface"
        case .midwater: return "Mid-water"
        case .bottom:   return "Bottom"
        case .all:      return "All depths"
        }
    }

    @ViewBuilder
    private func infoChip(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.secondary.opacity(0.12), in: Capsule())
    }
}
