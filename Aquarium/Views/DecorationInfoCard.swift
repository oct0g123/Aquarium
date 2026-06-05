import SwiftUI

struct DecorationInfoCard: View {
    let item: DecorationItem
    let onRemove: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(item.emoji)
                    .font(.system(size: 34))
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(.headline)
                    Text(item.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { onClose() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text(item.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)

            if !item.compatibleThemes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Best in")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        ForEach(item.compatibleThemes) { theme in
                            Label(theme.rawValue, systemImage: theme.icon)
                                .font(.caption2)
                                .lineLimit(1)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(theme.swiftUIColor.opacity(0.2), in: Capsule())
                        }
                    }
                }
            }

            infoChip(item.category.rawValue, icon: item.category.icon)

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
        .frame(width: 250)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 8)
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
