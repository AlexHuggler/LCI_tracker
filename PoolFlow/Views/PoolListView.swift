import SwiftUI
import SwiftData
import MapKit

/// Route view showing today's pools in service order.
/// Supports drag-and-drop reordering and one-tap Apple Maps launch.
struct PoolListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PoolListViewModel()
    @Query(sort: \Pool.routeOrder) private var allPools: [Pool]
    @State private var showingAddPool = false
    @State private var showingQuickLog: Pool?

    private var todaysPools: [Pool] {
        allPools.filter { $0.serviceDayOfWeek == viewModel.selectedDayOfWeek }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayPicker
                poolList
            }
            .navigationTitle("Route")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPool = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddPool) {
                AddPoolView()
            }
            .sheet(item: $showingQuickLog) { pool in
                QuickLogView(pool: pool)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Day Picker

    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    let symbols = Calendar.current.shortWeekdaySymbols
                    let label = symbols[day - 1]
                    let isSelected = day == viewModel.selectedDayOfWeek

                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            viewModel.selectedDayOfWeek = day
                        }
                        #if canImport(UIKit)
                        Theme.hapticLight()
                        #endif
                    } label: {
                        Text(label)
                            .font(.headline)
                            .fontWeight(isSelected ? .bold : .regular)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .frame(width: 48, height: 48)
                            .background(isSelected ? Color.blue : Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Pool List

    private var poolList: some View {
        Group {
            if todaysPools.isEmpty {
                ContentUnavailableView(
                    "No Pools on \(viewModel.dayLabel)",
                    systemImage: "drop.triangle",
                    description: Text("Tap + to add a pool to this day's route.")
                )
            } else {
                List {
                    ForEach(todaysPools) { pool in
                        NavigationLink {
                            PoolDetailView(pool: pool)
                        } label: {
                            poolRow(pool)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                showingQuickLog = pool
                            } label: {
                                Label("Log", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                    }
                    .onMove { source, destination in
                        viewModel.movePool(from: source, to: destination, in: todaysPools)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func poolRow(_ pool: Pool) -> some View {
        HStack(spacing: 12) {
            // Route order badge
            Text("\(pool.routeOrder + 1)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(.blue))

            VStack(alignment: .leading, spacing: 2) {
                Text(pool.customerName)
                    .font(.headline)
                Text(pool.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // LSI badge
            let lsi = LSICalculator.calculate(for: pool)
            Text(String(format: "%+.1f", lsi.lsiValue))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Theme.lsiColor(for: lsi.status))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.lsiColor(for: lsi.status).opacity(Theme.badgeTintOpacity))
                .clipShape(Capsule())

            // Directions button — large for gloved hands
            Button {
                openInMaps(pool)
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            .frame(width: Theme.minTouchTarget, height: Theme.minTouchTarget)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Maps

    private func openInMaps(_ pool: Pool) {
        if pool.latitude == 0.0 && pool.longitude == 0.0 {
            // No coordinates — open Apple Maps with address search instead
            let query = pool.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "http://maps.apple.com/?daddr=\(query)&dirflg=d") {
                UIApplication.shared.open(url)
            }
        } else {
            let coordinate = CLLocationCoordinate2D(
                latitude: pool.latitude,
                longitude: pool.longitude
            )
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = pool.customerName
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        }
    }
}
