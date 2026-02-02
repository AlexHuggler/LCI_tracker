import SwiftUI
import SwiftData

/// Simple form for adding a new pool to the route.
/// Large text fields and minimal required inputs for quick entry.
struct AddPoolView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var customerName = ""
    @State private var address = ""
    @State private var monthlyFee = "150"
    @State private var poolVolume = "15000"
    @State private var serviceDayOfWeek = Calendar.current.component(.weekday, from: Date())
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer") {
                    TextField("Customer Name", text: $customerName)
                        .font(.title3)
                    TextField("Address", text: $address)
                        .font(.title3)
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
                    Button("Save") {
                        savePool()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(customerName.isEmpty || address.isEmpty)
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
    }
}
