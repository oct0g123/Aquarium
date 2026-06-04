import SwiftUI

struct TankCustomizationView: View {
    @Environment(AppModel.self) private var appModel
    @State private var draftConfig: TankConfiguration = .init()

    var body: some View {
        Form {
            Section("Tank Identity") {
                HStack {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                    TextField("Tank name", text: $draftConfig.tankName)
                }

                Picker("Size", selection: $draftConfig.tankSize) {
                    ForEach(TankSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
            }

            Section("Theme") {
                ForEach(TankTheme.allCases) { theme in
                    themeRow(theme)
                }
            }

            Section("Lighting") {
                ForEach(LightingMode.allCases) { mode in
                    lightingRow(mode)
                }
            }

            Section("Substrate") {
                Picker("Substrate", selection: $draftConfig.substrate) {
                    ForEach(SubstrateType.allCases) { sub in
                        HStack {
                            Circle()
                                .fill(sub.color.swiftUIColor)
                                .frame(width: 14, height: 14)
                            Text(sub.rawValue)
                        }
                        .tag(sub)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Extras") {
                Toggle(isOn: $draftConfig.bubblesEnabled) {
                    Label("Bubble streams", systemImage: "bubble.right.fill")
                }
                Toggle(isOn: $draftConfig.plantsEnabled) {
                    Label("Background plants", systemImage: "leaf.fill")
                }
                Toggle(isOn: $draftConfig.glowEnabled) {
                    Label("Bioluminescent glow", systemImage: "sparkles")
                }
            }

            Section {
                Button {
                    appModel.store.applyConfig(draftConfig)
                } label: {
                    Label("Apply Changes", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            draftConfig = appModel.store.tankConfig
        }
    }

    // MARK: - Row Builders

    @ViewBuilder
    private func themeRow(_ theme: TankTheme) -> some View {
        Button {
            draftConfig.theme = theme
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(theme.swiftUIColor.opacity(0.25))
                    Image(systemName: theme.icon)
                        .foregroundStyle(theme.swiftUIColor)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(theme.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if draftConfig.theme == theme {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func lightingRow(_ mode: LightingMode) -> some View {
        Button {
            draftConfig.lighting = mode
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(mode.swiftUILightColor.opacity(0.25))
                    Image(systemName: mode.icon)
                        .foregroundStyle(mode.swiftUILightColor)
                }
                .frame(width: 36, height: 36)

                Text(mode.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                if draftConfig.lighting == mode {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers
private extension LightingMode {
    var swiftUILightColor: Color {
        let c = lightColor
        return Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z))
    }
}

private extension SIMD4<Float> {
    var swiftUIColor: Color {
        Color(red: Double(x), green: Double(y), blue: Double(z))
    }
}
