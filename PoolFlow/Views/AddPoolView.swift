import SwiftUI
import SwiftData
import CoreLocation

/// Simple form for adding a new pool to the route.
/// Large text fields and minimal required inputs for quick entry.
/// Geocodes the address on save to populate lat/lon for directions (D5/F4).
struct AddPoolView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var customerName = ""
    @State private var address = ""
    @State private var monthlyFee = "150"
    @State private var poolVolume = "15000"
    @State private var serviceDayOfWeek = Calendar.current.component(.weekday, from: Date())
    @State private var notes = ""
    @State private var isSaving = false

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
            .navigationTitle("Add Pool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            isSaving = true
                            savePool()
                        }
                        .fontWeight(.bold)
                        .disabled(customerName.isEmpty || address.isEmpty)
                    }
                }
            }
        }
    }

    private func savePool() {
        let pool = Pool(
            customerName: customerName,
            address: address,
            monthlyServiceFee: Double(monthlyFee) ?? 150.0,
            poolVolumeGallons: Double(poolVolume) ?? 15_000.0,
            notes: notes,
            serviceDayOfWeek: serviceDayOfWeek
        )
        modelContext.insert(pool)

        // A10: Haptic confirmation on save
        #if canImport(UIKit)
        Theme.hapticSuccess()
        #endif

        // CRIT-3: Capture the pool's persistent ID and the container before dismiss.
        // After dismiss, the view's @Environment(\.modelContext) may be invalid,
        // so we resolve the pool via the container's mainContext instead.
        let poolID = pool.persistentModelID
        let container = modelContext.container

        // A10: Dismiss immediately — geocoding continues in background
        dismiss()

        // Geocode the address asynchronously to populate lat/lon.
        // The pool is already saved locally (offline-first); coordinates
        // will update in the background when connectivity allows.
        let geocoder = CLGeocoder()
        let addressToGeocode = address
        Task {
            do {
                let placemarks = try await geocoder.geocodeAddressString(addressToGeocode)
                if let location = placemarks.first?.location {
                    await MainActor.run {
                        // Re-fetch the pool from the container's mainContext —
                        // safe even after the AddPoolView has been dismissed.
                        let context = container.mainContext
                        if let savedPool = context.model(for: poolID) as? Pool {
                            savedPool.latitude = location.coordinate.latitude
                            savedPool.longitude = location.coordinate.longitude
                        }
                    }
                }
            } catch {
                // Geocoding failed (no network, bad address) — directions
                // will fall back to address-string search in openInMaps().
            }
        }
    }
}
