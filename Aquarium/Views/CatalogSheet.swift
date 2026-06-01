import SwiftUI

// Tabbed catalog sheet — fish, decorations, themes
struct CatalogSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TabView(selection: Binding(
                get: { appModel.catalogTab },
                set: { appModel.catalogTab = $0 }
            )) {
                FishCatalogView()
                    .tabItem { Label("Fish", systemImage: "fish.fill") }
                    .tag(AppModel.CatalogTab.fish)

                DecorationCatalogView()
                    .tabItem { Label("Decorations", systemImage: "leaf.fill") }
                    .tag(AppModel.CatalogTab.decorations)

                TankCustomizationView()
                    .tabItem { Label("Theme", systemImage: "paintbrush.fill") }
                    .tag(AppModel.CatalogTab.themes)
            }
            .navigationTitle(appModel.catalogTab.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 540, minHeight: 420)
    }
}

private extension AppModel.CatalogTab {
    var navigationTitle: String {
        switch self {
        case .fish:        return "Add Fish"
        case .decorations: return "Decorations"
        case .themes:      return "Tank Setup"
        }
    }
}
