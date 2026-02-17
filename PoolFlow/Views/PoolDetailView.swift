import SwiftUI
import SwiftData

/// Detail view for a single pool showing water chemistry, LSI status,
/// dosing recommendations, profit tracking, and service history.
struct PoolDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var pool: Pool
    @State private var dosingVM = DosingViewModel()
    @State private var showDosingCalculator = false
    @State private var showQuickLog = false
    @State private var showEditPool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                customerHeader
                lsiSummaryCard
                chemistryGrid
                profitCard
                actionButtons
                serviceHistorySection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(pool.customerName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditPool = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showDosingCalculator) {
            NavigationStack {
                DosingCalculatorView(pool: pool)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showDosingCalculator = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showQuickLog) {
            QuickLogView(pool: pool)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showEditPool) {
            EditPoolView(pool: pool)
        }
        .onAppear {
            dosingVM.loadFromPool(pool)
        }
    }

    // MARK: - Customer Header

    private var customerHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pool.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !pool.notes.isEmpty {
                Text(pool.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
    }

    // MARK: - LSI Summary

    private var lsiSummaryCard: some View {
        let lsi = LSICalculator.calculate(for: pool)
        return VStack(spacing: 8) {
            Text("LSI")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "%+.2f", lsi.lsiValue))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.lsiColor(for: lsi.status))
                .contentTransition(.numericText(value: lsi.lsiValue))
            Text(lsi.status.rawValue)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.lsiColor(for: lsi.status))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
    }

    // MARK: - Chemistry Grid (C6: with range indicators)

    private var chemistryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            chemistryTile(
                "pH",
                value: String(format: "%.1f", pool.pH),
                unit: "",
                color: .purple,
                status: Theme.pHStatus(pool.pH)
            )
            chemistryTile(
                "Temp",
                value: String(format: "%.0f", pool.waterTempF),
                unit: "°F",
                color: .red,
                status: Theme.tempStatus(pool.waterTempF)
            )
            chemistryTile(
                "Calcium",
                value: String(format: "%.0f", pool.calciumHardness),
                unit: "ppm",
                color: .cyan,
                status: Theme.calciumStatus(pool.calciumHardness)
            )
            chemistryTile(
                "Alkalinity",
                value: String(format: "%.0f", pool.totalAlkalinity),
                unit: "ppm",
                color: .teal,
                status: Theme.alkalinityStatus(pool.totalAlkalinity)
            )
        }
    }

    private func chemistryTile(_ label: String, value: String, unit: String, color: Color, status: Theme.ReadingStatus) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            // C6: Range indicator
            Text(Theme.readingStatusLabel(status))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.readingStatusColor(status))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(Theme.cardTintOpacity))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
    }

    // MARK: - Profit Card

    private var profitCard: some View {
        let analysis = DosingEngine.profitAnalysis(
            monthlyFee: pool.monthlyServiceFee,
            serviceEvents: pool.serviceEvents
        )
        return VStack(spacing: 8) {
            HStack {
                Text("MONTHLY PROFIT")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if analysis.isInTheRed {
                    Text("IN THE RED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.red))
                }
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Fee")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(String(format: "%.0f", pool.monthlyServiceFee))")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .center) {
                    Text("Chem Cost")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(String(format: "%.2f", analysis.totalChemCost))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Profit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(String(format: "%.2f", analysis.profit))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(analysis.isInTheRed ? .red : .green)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
    }

    // MARK: - Action Buttons (large for gloved hands)

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary: Quick Log (P1 — core workflow)
            Button {
                showQuickLog = true
            } label: {
                Label("Quick Log Service", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
            .frame(minHeight: Theme.buttonHeight)

            // Secondary: Full Dosing Calculator
            Button {
                showDosingCalculator = true
            } label: {
                Label("Run Dosing Calculator", systemImage: "drop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
            .frame(minHeight: Theme.buttonHeight)
        }
    }

    // MARK: - Service History (B1)

    private var recentEvents: [ServiceEvent] {
        pool.serviceEvents
            .sorted(by: { $0.timestamp > $1.timestamp })
            .prefix(10)
            .map { $0 }
    }

    private var serviceHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SERVICE HISTORY")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(pool.serviceEvents.count) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if recentEvents.isEmpty {
                Text("No service visits recorded yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                ForEach(recentEvents) { event in
                    serviceEventRow(event)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
    }

    private func serviceEventRow(_ event: ServiceEvent) -> some View {
        let lsiStatus = LSICalculator.LSIResult(
            lsiValue: event.lsiValue,
            temperatureFactor: 0, calciumFactor: 0, alkalinityFactor: 0,
            pH: event.pH, tdsFactor: 0
        ).status

        return HStack(spacing: 10) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(event.timestamp, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(event.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // LSI value
            Text(String(format: "%+.2f", event.lsiValue))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Theme.lsiColor(for: lsiStatus))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Theme.lsiColor(for: lsiStatus).opacity(Theme.badgeTintOpacity))
                .clipShape(Capsule())

            // Key readings
            VStack(alignment: .trailing, spacing: 2) {
                Text("pH \(String(format: "%.1f", event.pH))")
                    .font(.caption)
                    .monospacedDigit()
                Text("$\(String(format: "%.2f", event.totalChemicalCost))")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            // Photo indicator
            if event.photoData != nil {
                Image(systemName: "camera.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Edit Pool View (A8)

struct EditPoolView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var pool: Pool

    @State private var customerName: String = ""
    @State private var address: String = ""
    @State private var monthlyFee: String = ""
    @State private var poolVolume: String = ""
    @State private var serviceDayOfWeek: Int = 2
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer") {
                    TextField("Customer Name", text: $customerName)
                        .font(.title3)
                    TextField("Address", text: $address)
                        .font(.title3)
                        .textContentType(.fullStreetAddress)
                }

                Section("Service") {
                    Picker("Service Day", selection: $serviceDayOfWeek) {
                        ForEach(1...7, id: \.self) { day in
                            Text(Calendar.current.weekdaySymbols[day - 1]).tag(day)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack {
                        Text("Monthly Fee $")
                        TextField("150", text: $monthlyFee)
                            .keyboardType(.decimalPad)
                    }
                    .font(.title3)

                    HStack {
                        Text("Pool Volume (gal)")
                        TextField("15000", text: $poolVolume)
                            .keyboardType(.numberPad)
                    }
                    .font(.title3)
                }

                Section("Notes") {
                    TextField("Gate code, dog, etc.", text: $notes)
                }
            }
            .navigationTitle("Edit Pool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.bold)
                    .disabled(customerName.isEmpty || address.isEmpty)
                }
            }
            .onAppear {
                customerName = pool.customerName
                address = pool.address
                monthlyFee = String(format: "%.0f", pool.monthlyServiceFee)
                poolVolume = String(format: "%.0f", pool.poolVolumeGallons)
                serviceDayOfWeek = pool.serviceDayOfWeek
                notes = pool.notes
            }
        }
    }

    private func saveChanges() {
        pool.customerName = customerName
        pool.address = address
        pool.monthlyServiceFee = Double(monthlyFee) ?? pool.monthlyServiceFee
        pool.poolVolumeGallons = Double(poolVolume) ?? pool.poolVolumeGallons
        pool.serviceDayOfWeek = serviceDayOfWeek
        pool.notes = notes
        pool.updatedAt = Date()

        #if canImport(UIKit)
        Theme.hapticSuccess()
        #endif

        dismiss()
    }
}
