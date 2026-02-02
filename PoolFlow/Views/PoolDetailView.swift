import SwiftUI

/// Detail view for a single pool showing water chemistry, LSI status,
/// dosing recommendations, and profit tracking.
struct PoolDetailView: View {
    @Bindable var pool: Pool
    @State private var dosingVM = DosingViewModel()
    @State private var showDosingCalculator = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                customerHeader
                lsiSummaryCard
                chemistryGrid
                profitCard
                actionButtons
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(pool.customerName)
        .navigationBarTitleDisplayMode(.large)
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
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                .foregroundStyle(lsiColor(lsi.status))
            Text(lsi.status.rawValue)
                .fontWeight(.semibold)
                .foregroundStyle(lsiColor(lsi.status))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Chemistry Grid

    private var chemistryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            chemistryTile("pH", value: String(format: "%.1f", pool.pH), unit: "", color: .purple)
            chemistryTile("Temp", value: String(format: "%.0f", pool.waterTempF), unit: "°F", color: .red)
            chemistryTile("Calcium", value: String(format: "%.0f", pool.calciumHardness), unit: "ppm", color: .cyan)
            chemistryTile("Alkalinity", value: String(format: "%.0f", pool.totalAlkalinity), unit: "ppm", color: .teal)
        }
    }

    private func chemistryTile(_ label: String, value: String, unit: String, color: Color) -> some View {
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
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Buttons (large for gloved hands)

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showDosingCalculator = true
            } label: {
                Label("Run Dosing Calculator", systemImage: "drop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .frame(minHeight: 56)
        }
    }

    private func lsiColor(_ status: LSICalculator.WaterCondition) -> Color {
        switch status {
        case .corrosive: return .blue
        case .balanced: return .green
        case .scaleForming: return .orange
        }
    }
}
