import SwiftUI

struct TankCustomizationView: View {
    @Environment(AppModel.self) private var appModel

    // Proxy binding that reads from the store and saves on every write.
    // This ensures changes persist immediately without a separate "Apply" tap.
    private var config: TankConfiguration {
        get { appModel.store.tankConfig }
    }

    private func update(_ block: (inout TankConfiguration) -> Void) {
        var c = appModel.store.tankConfig
        block(&c)
        appModel.store.applyConfig(c)
    }

    var body: some View {
        Form {
            Section("Tank Identity") {
                HStack {
                    Image(systemName: "pencil").foregroundStyle(.secondary)
                    TextField("Tank name", text: Binding(
                        get: { appModel.store.tankConfig.tankName },
                        set: { update { $0.tankName = $1 } }
                    ))
                }

                Picker("Size", selection: Binding(
                    get: { appModel.store.tankConfig.tankSize },
                    set: { update { $0.tankSize = $1 } }
                )) {
                    ForEach(TankSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
            }

            Section("Theme") {
                ForEach(TankTheme.allCases) { theme in themeRow(theme) }
            }

            Section("Lighting") {
                ForEach(LightingMode.allCases) { mode in lightingRow(mode) }
            }

            Section("Substrate") {
                Picker("Substrate", selection: Binding(
                    get: { appModel.store.tankConfig.substrate },
                    set: { update { $0.substrate = $1 } }
                )) {
                    ForEach(SubstrateType.allCases) { sub in
                        HStack {
                            Circle().fill(sub.color.swiftUIColor).frame(width: 14, height: 14)
                            Text(sub.rawValue)
                        }
                        .tag(sub)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Extras") {
                Toggle(isOn: Binding(
                    get: { appModel.store.tankConfig.bubblesEnabled },
                    set: { update { $0.bubblesEnabled = $1 } }
                )) { Label("Bubble streams", systemImage: "bubble.right.fill") }

                Toggle(isOn: Binding(
                    get: { appModel.store.tankConfig.plantsEnabled },
                    set: { update { $0.plantsEnabled = $1 } }
                )) { Label("Background plants", systemImage: "leaf.fill") }

                Toggle(isOn: Binding(
                    get: { appModel.store.tankConfig.glowEnabled },
                    set: { update { $0.glowEnabled = $1 } }
                )) { Label("Bioluminescent glow", systemImage: "sparkles") }
            }
        }
    }

    // MARK: - Row Builders

    @ViewBuilder
    private func themeRow(_ theme: TankTheme) -> some View {
        Button { update { $0.theme = theme } } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(theme.swiftUIColor.opacity(0.25))
                    Image(systemName: theme.icon).foregroundStyle(theme.swiftUIColor)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.rawValue).font(.subheadline.bold())
                    Text(theme.description).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                if appModel.store.tankConfig.theme == theme {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func lightingRow(_ mode: LightingMode) -> some View {
        Button { update { $0.lighting = mode } } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(mode.swiftUILightColor.opacity(0.25))
                    Image(systemName: mode.icon).foregroundStyle(mode.swiftUILightColor)
                }
                .frame(width: 36, height: 36)
                Text(mode.rawValue).font(.subheadline)
                Spacer()
                if appModel.store.tankConfig.lighting == mode {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
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
