import SwiftUI
import SwiftData
import MapKit

/// Route view showing today's pools in service order.
/// Supports drag-and-drop reordering, one-tap Apple Maps launch,
/// search, route progress tracking, and context menus.
struct PoolListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PoolListViewModel()
    @Query(sort: \Pool.routeOrder) private var allPools: [Pool]
    @State private var showingAddPool = false
    @State private var showingQuickLog: Pool?
    @State private var searchText = ""
    @State private var showRouteComplete = false
    @State private var poolToDelete: Pool?
    @State private var showDeleteConfirmation = false

    private var todaysPools: [Pool] {
        let dayPools = allPools.filter { $0.serviceDayOfWeek == viewModel.selectedDayOfWeek }
        if searchText.isEmpty { return dayPools }
        return dayPools.filter {
            $0.customerName.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    // A1/A2: Service tracking
    private func isServicedToday(_ pool: Pool) -> Bool {
        pool.serviceEvents.contains { Calendar.current.isDateInToday($0.timestamp) }
    }

    private var servicedCount: Int {
        // Use unfiltered day pools for accurate progress
        let dayPools = allPools.filter { $0.serviceDayOfWeek == viewModel.selectedDayOfWeek }
        return dayPools.filter { isServicedToday($0) }.count
    }

    private var totalDayPools: Int {
        allPools.filter { $0.serviceDayOfWeek == viewModel.selectedDayOfWeek }.count
    }

    // B2: Pool count per day
    private func poolCount(for day: Int) -> Int {
        allPools.filter { $0.serviceDayOfWeek == day }.count
    }

    // A3: Last serviced date
    private func lastServiceDate(_ pool: Pool) -> Date? {
        pool.serviceEvents
            .max(by: { $0.timestamp < $1.timestamp })?
            .timestamp
    }

    private func lastServiceLabel(_ pool: Pool) -> String? {
        guard let date = lastServiceDate(pool) else { return nil }
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days < 7 { return "\(days)d ago" }
        let weeks = days / 7
        return "\(weeks)w ago"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayPicker

                if totalDayPools > 0 {
                    routeProgress
                }

                poolList
            }
            .navigationTitle("Route")
            .searchable(text: $searchText, prompt: "Search pools")
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
            .alert("Delete Pool?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let pool = poolToDelete {
                        modelContext.delete(pool)
                        poolToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    poolToDelete = nil
                }
            } message: {
                if let pool = poolToDelete {
                    Text("This will permanently delete \(pool.customerName) and all service history.")
                }
            }
            .overlay {
                if showRouteComplete {
                    routeCompleteOverlay
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onChange(of: servicedCount) { oldVal, newVal in
                // C3: Trigger celebration when all pools for the day are serviced
                if newVal > 0 && newVal == totalDayPools && oldVal < newVal {
                    #if canImport(UIKit)
                    Theme.hapticSuccess()
                    #endif
                    withAnimation(.spring(duration: 0.5)) {
                        showRouteComplete = true
                    }
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation(.easeOut(duration: 0.3)) {
                            showRouteComplete = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - Day Picker (B2: with pool counts)

    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    let symbols = Calendar.current.shortWeekdaySymbols
                    let label = symbols[day - 1]
                    let isSelected = day == viewModel.selectedDayOfWeek
                    let count = poolCount(for: day)

                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            viewModel.selectedDayOfWeek = day
                        }
                        #if canImport(UIKit)
                        Theme.hapticLight()
                        #endif
                    } label: {
                        VStack(spacing: 2) {
                            Text(label)
                                .font(.headline)
                                .fontWeight(isSelected ? .bold : .regular)
                                .foregroundStyle(isSelected ? .white : .primary)

                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                            }
                        }
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

    // MARK: - Route Progress (A2)

    private var routeProgress: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(servicedCount) of \(totalDayPools) serviced")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                if servicedCount == totalDayPools && totalDayPools > 0 {
                    Text("Complete")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(servicedCount == totalDayPools ? Color.green : Color.blue)
                        .frame(
                            width: totalDayPools > 0
                                ? geometry.size.width * CGFloat(servicedCount) / CGFloat(totalDayPools)
                                : 0,
                            height: 6
                        )
                        .animation(.spring(duration: 0.4), value: servicedCount)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Pool List

    private var poolList: some View {
        Group {
            if todaysPools.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty
                        ? "No Pools on \(viewModel.dayLabel)"
                        : "No Results",
                    systemImage: searchText.isEmpty ? "drop.triangle" : "magnifyingglass",
                    description: Text(
                        searchText.isEmpty
                            ? "Tap + to add a pool to this day's route."
                            : "No pools match \"\(searchText)\"."
                    )
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
                        .swipeActions(edge: .leading) {
                            Button(role: .destructive) {
                                poolToDelete = pool
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                showingQuickLog = pool
                            } label: {
                                Label("Quick Log", systemImage: "checkmark.circle")
                            }

                            Button {
                                openInMaps(pool)
                            } label: {
                                Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle")
                            }

                            Divider()

                            Button(role: .destructive) {
                                poolToDelete = pool
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete Pool", systemImage: "trash")
                            }
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
            // Route order badge — shows checkmark if serviced today (A1)
            ZStack {
                if isServicedToday(pool) {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.green))
                } else {
                    Text("\(pool.routeOrder + 1)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.blue))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(pool.customerName)
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(pool.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    // A3: Last serviced timestamp
                    if let serviceLabel = lastServiceLabel(pool) {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(serviceLabel)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(
                                Calendar.current.isDateInToday(lastServiceDate(pool) ?? .distantPast)
                                    ? .green
                                    : .secondary
                            )
                    }
                }
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

    // MARK: - Route Complete Overlay (C3)

    private var routeCompleteOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Route Complete!")
                .font(.title2)
                .fontWeight(.bold)
            Text("All \(totalDayPools) pools serviced")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
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
