import SwiftUI
import SwiftData

/// Main dosing calculator screen.
///
/// Design principles (from spec):
/// - High-contrast colors for outdoor visibility
/// - Large touch targets for gloved/wet hands ("One-Tap Rule")
/// - Minimal depth — all readings and results on one scrollable screen
struct DosingCalculatorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DosingViewModel()
    @Query private var inventory: [ChemicalInventory]
    @State private var showSavedConfirmation = false

    var pool: Pool?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                lsiGaugeSection
                waterReadingsSection
                recommendationsSection

                if pool != nil {
                    saveButton
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dosing Calculator")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if let pool {
                viewModel.loadFromPool(pool)
            }
            viewModel.loadCosts(from: inventory)
        }
        .onChange(of: viewModel.lsiResult.lsiValue) {
            viewModel.checkHapticTrigger()
        }
        .overlay {
            if showSavedConfirmation {
                savedToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - LSI Gauge

    private var lsiColor: Color {
        Theme.lsiColor(for: viewModel.lsiResult.status)
    }

    private var lsiGaugeSection: some View {
        VStack(spacing: 8) {
            Text("LSI INDEX")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            Text(String(format: "%+.2f", viewModel.lsiResult.lsiValue))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(lsiColor)
                .contentTransition(.numericText(value: viewModel.lsiResult.lsiValue))
                .animation(.snappy(duration: 0.25), value: viewModel.lsiResult.lsiValue)

            Text(viewModel.lsiResult.status.rawValue.uppercased())
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(lsiColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(lsiColor.opacity(Theme.badgeTintOpacity))
                .clipShape(Capsule())
                .animation(.easeInOut(duration: 0.3), value: viewModel.lsiResult.status)

            Text(viewModel.lsiResult.status.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
    }

    // MARK: - Water Readings Input

    private var waterReadingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WATER READINGS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            readingRow(
                label: "pH",
                value: $viewModel.pH,
                range: 6.0...9.0,
                step: 0.1,
                format: "%.1f",
                unit: ""
            )

            readingRow(
                label: "Temp",
                value: $viewModel.waterTempF,
                range: 32...120,
                step: 2,
                format: "%.0f",
                unit: "°F"
            )

            readingRow(
                label: "Calcium",
                value: $viewModel.calciumHardness,
                range: 0...1000,
                step: 25,
                format: "%.0f",
                unit: "ppm"
            )

            readingRow(
                label: "Alkalinity",
                value: $viewModel.totalAlkalinity,
                range: 0...500,
                step: 10,
                format: "%.0f",
                unit: "ppm"
            )

            readingRow(
                label: "TDS",
                value: $viewModel.totalDissolvedSolids,
                range: 0...5000,
                step: 100,
                format: "%.0f",
                unit: "ppm"
            )

            readingRow(
                label: "Volume",
                value: $viewModel.poolVolumeGallons,
                range: 5000...50000,
                step: 1000,
                format: "%.0f",
                unit: "gal"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTION STEPS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                Spacer()
                if viewModel.totalEstimatedCost > 0 {
                    Text("Est. Cost: $\(String(format: "%.2f", viewModel.totalEstimatedCost))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            }

            ForEach(viewModel.recommendations) { rec in
                recommendationCard(rec)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
    }

    // MARK: - Save Button (F3)

    private var saveButton: some View {
        Button {
            guard let pool else { return }
            viewModel.saveToPool(pool)
            _ = viewModel.createServiceEvent(for: pool, in: modelContext)
            #if canImport(UIKit)
            Theme.hapticSuccess()
            #endif
            withAnimation(.spring(duration: 0.4)) {
                showSavedConfirmation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showSavedConfirmation = false }
            }
        } label: {
            Label("Save Readings & Log Service", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .frame(minHeight: Theme.buttonHeight)
    }

    private var savedToast: some View {
        VStack {
            Text("Service Logged")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(.green))
                .shadow(radius: 8)
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Components

    private func readingRow(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String,
        unit: String
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.headline)
                    .frame(width: 90, alignment: .leading)
                Spacer()
                Text("\(String(format: format, value.wrappedValue)) \(unit)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: value.wrappedValue))
                    .animation(.snappy(duration: 0.2), value: value.wrappedValue)
            }

            HStack(spacing: 12) {
                Button {
                    let new = value.wrappedValue - step
                    if new >= range.lowerBound {
                        value.wrappedValue = new
                        #if canImport(UIKit)
                        Theme.hapticLight()
                        #endif
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .frame(width: Theme.minTouchTarget, height: Theme.minTouchTarget)

                Slider(value: value, in: range, step: step)
                    .tint(Theme.sliderTint(for: label))

                Button {
                    let new = value.wrappedValue + step
                    if new <= range.upperBound {
                        value.wrappedValue = new
                        #if canImport(UIKit)
                        Theme.hapticLight()
                        #endif
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .frame(width: Theme.minTouchTarget, height: Theme.minTouchTarget)
            }
        }
        .padding(.vertical, 4)
    }

    private func recommendationCard(_ rec: DosingEngine.DosingRecommendation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if rec.priority > 0 {
                Text("\(rec.priority)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Theme.chemicalColor(for: rec.chemicalType)))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(rec.instruction)
                    .font(.body)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)

                if rec.estimatedCost > 0 {
                    Text("Cost: $\(String(format: "%.2f", rec.estimatedCost))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.chemicalColor(for: rec.chemicalType).opacity(Theme.cardTintOpacity))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
    }
}
