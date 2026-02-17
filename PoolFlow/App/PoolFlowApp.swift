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
                .onAppear {
                    seedDefaultInventoryIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    /// Seeds the default chemical catalog on first launch (D7/F5).
    /// Only inserts if the inventory table is empty so we never duplicate.
    private func seedDefaultInventoryIfNeeded() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<ChemicalInventory>()
        let count = (try? context.fetchCount(descriptor)) ?? 0

        if count == 0 {
            for chemical in ChemicalInventory.defaultCatalog() {
                context.insert(chemical)
            }
        }
    }
}

/// Root view with tab navigation. Large icons for wet/gloved hands.
/// C7: Badge shows count of unserviced pools for today.
struct ContentView: View {
    @Query(sort: \Pool.routeOrder) private var allPools: [Pool]

    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: Date())
    }

    private var unservicedTodayCount: Int {
        let todayPools = allPools.filter { $0.serviceDayOfWeek == todayWeekday }
        let unserviced = todayPools.filter { pool in
            !pool.serviceEvents.contains { Calendar.current.isDateInToday($0.timestamp) }
        }
        return unserviced.count
    }

    var body: some View {
        TabView {
            PoolListView()
                .tabItem {
                    Label("Route", systemImage: "map.fill")
                }
                .badge(unservicedTodayCount > 0 ? unservicedTodayCount : 0)

            NavigationStack {
                DosingCalculatorView()
            }
            .tabItem {
                Label("Dose", systemImage: "drop.fill")
            }
        }
    }
}
