import Foundation
import SwiftUI
import SwiftData

/// ViewModel for the Dosing Calculator screen.
/// Binds water chemistry inputs to the LSI engine and produces
/// live dosing recommendations as sliders/steppers change.
@Observable
final class DosingViewModel {
    // Input readings (bound to UI controls)
    var waterTempF: Double = 78.0
    var pH: Double = 7.4
    var calciumHardness: Double = 250.0
    var totalAlkalinity: Double = 100.0
    var totalDissolvedSolids: Double = 1000.0
    var poolVolumeGallons: Double = 15_000.0

    // Cost lookup (populated from inventory)
    var costLookup = DosingEngine.CostLookup()

    // Track previous status for haptic triggers
    private var previousStatus: LSICalculator.WaterCondition?

    // Computed results
    var lsiResult: LSICalculator.LSIResult {
        LSICalculator.calculate(
            pH: pH,
            waterTempF: waterTempF,
            calciumHardness: calciumHardness,
            totalAlkalinity: totalAlkalinity,
            tds: totalDissolvedSolids
        )
    }

    var recommendations: [DosingEngine.DosingRecommendation] {
        DosingEngine.recommend(
            lsiResult: lsiResult,
            currentPH: pH,
            currentTA: totalAlkalinity,
            currentCH: calciumHardness,
            poolVolumeGallons: poolVolumeGallons,
            costs: costLookup
        )
    }

    var totalEstimatedCost: Double {
        recommendations.reduce(0.0) { $0 + $1.estimatedCost }
    }

    /// Load readings from an existing Pool model.
    /// Prefers the most recent ServiceEvent readings (F2) over the Pool's static defaults.
    func loadFromPool(_ pool: Pool) {
        if let lastEvent = pool.serviceEvents
            .max(by: { $0.timestamp < $1.timestamp }) {
            // Use last service visit readings as the starting point
            waterTempF = lastEvent.waterTempF
            pH = lastEvent.pH
            calciumHardness = lastEvent.calciumHardness
            totalAlkalinity = lastEvent.totalAlkalinity
        } else {
            // No prior visits — use pool defaults
            waterTempF = pool.waterTempF
            pH = pool.pH
            calciumHardness = pool.calciumHardness
            totalAlkalinity = pool.totalAlkalinity
        }
        totalDissolvedSolids = pool.totalDissolvedSolids
        poolVolumeGallons = pool.poolVolumeGallons
    }

    /// Populate cost data from the user's actual ChemicalInventory.
    func loadCosts(from inventory: [ChemicalInventory]) {
        costLookup = DosingEngine.CostLookup(inventory: inventory)
    }

    /// Save current readings back to a Pool model (D4: includes volume).
    func saveToPool(_ pool: Pool) {
        pool.waterTempF = waterTempF
        pool.pH = pH
        pool.calciumHardness = calciumHardness
        pool.totalAlkalinity = totalAlkalinity
        pool.totalDissolvedSolids = totalDissolvedSolids
        pool.poolVolumeGallons = poolVolumeGallons
        pool.updatedAt = Date()
    }

    /// Create a ServiceEvent from the current readings and link it to the pool.
    func createServiceEvent(for pool: Pool, in context: ModelContext) -> ServiceEvent {
        let lsi = lsiResult
        let event = ServiceEvent(
            pool: pool,
            waterTempF: waterTempF,
            pH: pH,
            calciumHardness: calciumHardness,
            totalAlkalinity: totalAlkalinity,
            lsiValue: lsi.lsiValue,
            totalChemicalCost: totalEstimatedCost
        )
        context.insert(event)
        return event
    }

    /// Fire haptic when LSI status boundary is crossed (F1).
    func checkHapticTrigger() {
        let current = lsiResult.status
        if let previous = previousStatus, previous != current {
            #if canImport(UIKit)
            Theme.haptic(for: current)
            #endif
        }
        previousStatus = current
    }
}
