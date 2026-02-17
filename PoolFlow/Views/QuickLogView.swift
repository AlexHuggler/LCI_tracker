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

    // A4: Range bounds for steppers
    private static let phRange: ClosedRange<Double> = 6.0...9.0
    private static let tempRange: ClosedRange<Double> = 32...120
    private static let calciumRange: ClosedRange<Double> = 0...1000
    private static let alkalinityRange: ClosedRange<Double> = 0...500

    // A7: Single computed LSI to avoid double computation
    private var currentLSI: LSICalculator.LSIResult {
        LSICalculator.calculate(
            pH: pH,
            waterTempF: waterTempF,
            calciumHardness: calciumHardness,
            totalAlkalinity: totalAlkalinity,
            tds: pool.totalDissolvedSolids
        )
    }

    private var currentRecommendations: [DosingEngine.DosingRecommendation] {
        let costs = DosingEngine.CostLookup(inventory: inventory)
        return DosingEngine.recommend(
            lsiResult: currentLSI,
            currentPH: pH,
            currentTA: totalAlkalinity,
            currentCH: calciumHardness,
            poolVolumeGallons: pool.poolVolumeGallons,
            costs: costs
        )
    }

    private var totalEstimatedCost: Double {
        currentRecommendations.reduce(0.0) { $0 + $1.estimatedCost }
    }

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

    // MARK: - Readings Grid (A4: with range bounds)

    private var readingsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            compactStepper("pH", value: $pH, range: Self.phRange, step: 0.1, format: "%.1f")
            compactStepper("Temp °F", value: $waterTempF, range: Self.tempRange, step: 2, format: "%.0f")
            compactStepper("Calcium", value: $calciumHardness, range: Self.calciumRange, step: 25, format: "%.0f")
            compactStepper("Alk", value: $totalAlkalinity, range: Self.alkalinityRange, step: 10, format: "%.0f")
        }
    }

    private func compactStepper(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: String) -> some View {
        let atMin = value.wrappedValue <= range.lowerBound
        let atMax = value.wrappedValue >= range.upperBound

        return VStack(spacing: 6) {
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
                    let new = value.wrappedValue - step
                    if new >= range.lowerBound {
                        value.wrappedValue = new
                        #if canImport(UIKit)
                        Theme.hapticLight()
                        #endif
                    } else {
                        #if canImport(UIKit)
                        Theme.hapticError()
                        #endif
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(atMin ? .gray : .blue)
                }
                .frame(width: Theme.minTouchTarget, height: Theme.minTouchTarget)
                .disabled(atMin)

                Button {
                    let new = value.wrappedValue + step
                    if new <= range.upperBound {
                        value.wrappedValue = new
                        #if canImport(UIKit)
                        Theme.hapticLight()
                        #endif
                    } else {
                        #if canImport(UIKit)
                        Theme.hapticError()
                        #endif
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(atMax ? .gray : .blue)
                }
                .frame(width: Theme.minTouchTarget, height: Theme.minTouchTarget)
                .disabled(atMax)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
    }

    // MARK: - Photo (A5: with preview)

    private var photoSection: some View {
        VStack(spacing: 8) {
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

            // A5: Photo thumbnail preview
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
            }
        }
    }

    // MARK: - Notes (A6: multi-line)

    private var notesField: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $techNotes)
                .font(.body)
                .frame(minHeight: 72, maxHeight: 120)
                .scrollContentBackground(.hidden)

            if techNotes.isEmpty {
                Text("Notes (optional)")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.tileCornerRadius))
    }

    // MARK: - Cost Summary (A7: uses shared computation)

    private var costSummary: some View {
        HStack {
            Text("Estimated Chemical Cost")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("$\(String(format: "%.2f", totalEstimatedCost))")
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
        // A7: Reuse the shared computed cost instead of recalculating
        let event = ServiceEvent(
            pool: pool,
            waterTempF: waterTempF,
            pH: pH,
            calciumHardness: calciumHardness,
            totalAlkalinity: totalAlkalinity,
            lsiValue: currentLSI.lsiValue,
            photoData: photoData,
            totalChemicalCost: totalEstimatedCost,
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
