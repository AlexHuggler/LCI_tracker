import Foundation
import SwiftData

/// Core data model representing a customer's swimming pool.
/// Stores the water chemistry readings needed for LSI calculation,
/// customer info, and service scheduling data.
@Model
final class Pool {
    var id: UUID
    var customerName: String
    var address: String
    var latitude: Double
    var longitude: Double

    // Water chemistry readings
    var waterTempF: Double
    var pH: Double
    var calciumHardness: Double
    var totalAlkalinity: Double
    var totalDissolvedSolids: Double

    // Service & billing
    var monthlyServiceFee: Double
    var poolVolumeGallons: Double
    var notes: String

    // Scheduling
    var serviceDayOfWeek: Int // 1 = Sunday ... 7 = Saturday
    var routeOrder: Int

    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \ServiceEvent.pool)
    var serviceEvents: [ServiceEvent] = []

    init(
        customerName: String,
        address: String,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        waterTempF: Double = 78.0,
        pH: Double = 7.4,
        calciumHardness: Double = 250.0,
        totalAlkalinity: Double = 100.0,
        totalDissolvedSolids: Double = 1000.0,
        monthlyServiceFee: Double = 150.0,
        poolVolumeGallons: Double = 15_000.0,
        notes: String = "",
        serviceDayOfWeek: Int = 2,
        routeOrder: Int = 0
    ) {
        self.id = UUID()
        self.customerName = customerName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.waterTempF = waterTempF
        self.pH = pH
        self.calciumHardness = calciumHardness
        self.totalAlkalinity = totalAlkalinity
        self.totalDissolvedSolids = totalDissolvedSolids
        self.monthlyServiceFee = monthlyServiceFee
        self.poolVolumeGallons = poolVolumeGallons
        self.notes = notes
        self.serviceDayOfWeek = serviceDayOfWeek
        self.routeOrder = routeOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
