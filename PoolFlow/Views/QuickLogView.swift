import SwiftUI
import SwiftData
import PhotosUI

/// Quick Log half-sheet: the core field workflow.
///
/// Opened via swipe-action on the route list or the "Quick Log" button on pool detail.
/// Pre-fills with last visit's readings, allows quick adjustments, camera for proof
/// photo, and a single "Log & Done" tap to persist the ServiceEvent.
///
/// Design: minimal depth, large buttons, operates with wet/gloved hands.
struct QuickLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var inventory: [ChemicalInventory]

    let pool: Pool

    // Pre-filled readings
    @State private var pH: Double = 7.4
    @State private var waterTempF: Double = 78.0
    @State private var calciumHardness: Double = 250.0
    @State private var totalAlkalinity: Double = 100.0
    @State private var techNotes: String = ""

    // Photo
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    // Confirmation
    @State private var didSave = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    lsiBadge
                    readingsGrid
                    photoSection
                    notesField
                    costSummary
                    logButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Log Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { prefill() }
            .overlay {
                if didSave {
                    savedOverlay
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - LSI Badge

    private var currentLSI: LSICalculator.LSIResult {
        LSICalculator.calculate(
            pH: pH,
            waterTempF: waterTempF,
            calciumHardness: calciumHardness,
            totalAlkalinity: totalAlkalinity,
            tds: pool.totalDissolvedSolids
        )
    }

    private var lsiBadge: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text(pool.customerName)
                    .font(.headline)
                Text(pool.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "%+.2f", currentLSI.lsiValue))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Theme.lsiColor(for: currentLSI.status))
                .contentTransition(.numericText(value: currentLSI.lsiValue))
                .animation(.snappy(duration: 0.25), value: currentLSI.lsiValue)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
    }

    // MARK: - Readings Grid (compact for half-sheet)

    private var readingsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            compactStepper("pH", value: $pH, step: 0.1, format: "%.1f")
            compactStepper("Temp °F", value: $waterTempF, step: 2, format: "%.0f")
            compactStepper("Calcium", value: $calciumHardness, step: 25, format: "%.0f")
            compactStepper("Alk", value: $totalAlkalinity, step: 10, format: "%.0f")
        }
    }

    private func compactStepper(_ label: String, value: Binding<Double>, step: Double, format: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: format, value.wrappedValue))
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
                .contentTransition(.numericText(value: value.wrappedValue))
                .animation(.snappy(duration: 0.2), value: value.wrappedValue)
            HStack(spacing: 16) {
                Button {
                    value.wrappedValue -= step
                    #if canImport(UIKit)
                    Theme.hapticLight()
                    #endif
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .frame(width: Theme.minTouchTarget, height: Theme.minTouchTarget)

                Button {
                    value.wrappedValue += step
                    #if canImport(UIKit)
                    Theme.hapticLight()
                    #endif
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .frame(width: Theme.minTouchTarget, height: Theme.minTouchTarget)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
    }

    // MARK: - Photo

    private var photoSection: some View {
        HStack {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label(
                    photoData != nil ? "Photo Added" : "Add Proof Photo",
                    systemImage: photoData != nil ? "checkmark.circle.fill" : "camera.fill"
                )
                .font(.headline)
                .foregroundStyle(photoData != nil ? .green : .blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    // MARK: - Notes

    private var notesField: some View {
        TextField("Notes (optional)", text: $techNotes)
            .font(.body)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
    }

    // MARK: - Cost Summary

    private var costSummary: some View {
        let costs = DosingEngine.CostLookup(inventory: inventory)
        let recs = DosingEngine.recommend(
            lsiResult: currentLSI,
            currentPH: pH,
            currentTA: totalAlkalinity,
            currentCH: calciumHardness,
            poolVolumeGallons: pool.poolVolumeGallons,
            costs: costs
        )
        let total = recs.reduce(0.0) { $0 + $1.estimatedCost }

        return HStack {
            Text("Estimated Chemical Cost")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("$\(String(format: "%.2f", total))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.orange)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
    }

    // MARK: - Log Button

    private var logButton: some View {
        Button {
            saveServiceEvent()
        } label: {
            Label("Log & Done", systemImage: "checkmark.circle.fill")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .frame(minHeight: Theme.buttonHeight)
    }

    // MARK: - Save

    private func prefill() {
        if let lastEvent = pool.serviceEvents
            .sorted(by: { $0.timestamp > $1.timestamp })
            .first {
            pH = lastEvent.pH
            waterTempF = lastEvent.waterTempF
            calciumHardness = lastEvent.calciumHardness
            totalAlkalinity = lastEvent.totalAlkalinity
        } else {
            pH = pool.pH
            waterTempF = pool.waterTempF
            calciumHardness = pool.calciumHardness
            totalAlkalinity = pool.totalAlkalinity
        }
    }

    private func saveServiceEvent() {
        let costs = DosingEngine.CostLookup(inventory: inventory)
        let recs = DosingEngine.recommend(
            lsiResult: currentLSI,
            currentPH: pH,
            currentTA: totalAlkalinity,
            currentCH: calciumHardness,
            poolVolumeGallons: pool.poolVolumeGallons,
            costs: costs
        )
        let totalCost = recs.reduce(0.0) { $0 + $1.estimatedCost }

        let event = ServiceEvent(
            pool: pool,
            waterTempF: waterTempF,
            pH: pH,
            calciumHardness: calciumHardness,
            totalAlkalinity: totalAlkalinity,
            lsiValue: currentLSI.lsiValue,
            photoData: photoData,
            totalChemicalCost: totalCost,
            techNotes: techNotes
        )
        modelContext.insert(event)

        // Update pool's stored readings
        pool.waterTempF = waterTempF
        pool.pH = pH
        pool.calciumHardness = calciumHardness
        pool.totalAlkalinity = totalAlkalinity
        pool.updatedAt = Date()

        #if canImport(UIKit)
        Theme.hapticSuccess()
        #endif

        withAnimation(.spring(duration: 0.3)) {
            didSave = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }

    private var savedOverlay: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Logged")
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}
