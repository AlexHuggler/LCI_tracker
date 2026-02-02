import Foundation
import SwiftUI

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
            poolVolumeGallons: poolVolumeGallons
        )
    }

    var totalEstimatedCost: Double {
        recommendations.reduce(0.0) { $0 + $1.estimatedCost }
    }

    /// Load readings from an existing Pool model.
    func loadFromPool(_ pool: Pool) {
        waterTempF = pool.waterTempF
        pH = pool.pH
        calciumHardness = pool.calciumHardness
        totalAlkalinity = pool.totalAlkalinity
        totalDissolvedSolids = pool.totalDissolvedSolids
        poolVolumeGallons = pool.poolVollumeGallons
    }

    /// Save current readings back to a Pool model.
    func saveToPool(_ pool: Pool) {
        pool.waterTempF = waterTempF
        pool.pH = pH
        pool.calciumHardness = calciumHardness
        pool.totalAlkalinity = totalAlkalinity
        pool.totalDissolvedSolids = totalDissolvedSolids
        pool.updatedAt = Date()
    }
}
