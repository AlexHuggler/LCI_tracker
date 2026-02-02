import SwiftUI
import SwiftData

/// PoolFlow App entry point.
/// Configures the SwiftData ModelContainer for offline-first persistence
/// and sets up the root tab navigation.
@main
struct PoolFlowApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Pool.self,
            ServiceEvent.self,
            ChemicalDose.self,
            ChemicalInventory.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

/// Root view with tab navigation. Large icons for wet/gloved hands.
struct ContentView: View {
    var body: some View {
        TabView {
            PoolListView()
                .tabItem {
                    Label("Route", systemImage: "map.fill")
                }

            NavigationStack {
                DosingCalculatorView()
            }
            .tabItem {
                Label("Dose", systemImage: "drop.fill")
            }
        }
    }
}
