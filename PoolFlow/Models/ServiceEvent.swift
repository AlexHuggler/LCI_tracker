import Foundation
import SwiftData

/// A single service visit to a pool. Captures water readings at time of service,
/// chemicals applied, a proof-of-service photo, and the total chemical cost.
@Model
final class ServiceEvent {
    var id: UUID
    var pool: Pool?
    var timestamp: Date

    // Water readings at time of service
    var waterTempF: Double
    var pH: Double
    var calciumHardness: Double
    var totalAlkalinity: Double
    var lsiValue: Double

    // Proof of service photo (stored as JPEG data)
    @Attribute(.externalStorage)
    var photoData: Data?

    // Chemicals used during this visit
    @Relationship(deleteRule: .cascade, inverse: \ChemicalDose.serviceEvent)
    var chemicalDoses: [ChemicalDose] = []

    var totalChemicalCost: Double
    var techNotes: String

    init(
        pool: Pool? = nil,
        waterTempF: Double = 78.0,
        pH: Double = 7.4,
        calciumHardness: Double = 250.0,
        totalAlkalinity: Double = 100.0,
        lsiValue: Double = 0.0,
        photoData: Data? = nil,
        totalChemicalCost: Double = 0.0,
        techNotes: String = ""
    ) {
        self.id = UUID()
        self.pool = pool
        self.timestamp = Date()
        self.waterTempF = waterTempF
        self.pH = pH
        self.calciumHardness = calciumHardness
        self.totalAlkalinity = totalAlkalinity
        self.lsiValue = lsiValue
        self.photoData = photoData
        self.totalChemicalCost = totalChemicalCost
        self.techNotes = techNotes
    }
}

/// A specific chemical dose applied during a service event.
/// Links to ChemicalInventory for cost lookups.
@Model
final class ChemicalDose {
    var id: UUID
    var serviceEvent: ServiceEvent?
    var chemical: ChemicalInventory?

    var quantityOz: Double
    var cost: Double

    init(
        serviceEvent: ServiceEvent? = nil,
        chemical: ChemicalInventory? = nil,
        quantityOz: Double = 0.0,
        cost: Double = 0.0
    ) {
        self.id = UUID()
        self.serviceEvent = serviceEvent
        self.chemical = chemical
        self.quantityOz = quantityOz
        self.cost = cost
    }
}
