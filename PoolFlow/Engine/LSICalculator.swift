import Foundation

/// Langelier Saturation Index calculator.
///
/// Formula: LSI = pH + TF + CF + AF - 12.1
///
/// Where:
/// - pH  = measured pH of the water
/// - TF  = Temperature Factor (from lookup table)
/// - CF  = Calcium Hardness Factor (from lookup table, log10-based)
/// - AF  = Alkalinity Factor (from lookup table, log10-based)
///
/// LSI interpretation:
///   LSI < -0.3  → Water is corrosive (aggressive). Dissolves plaster, etches surfaces.
///   -0.3 to 0.3 → Balanced. Ideal operating range.
///   LSI > 0.3   → Water is scale-forming. Calcium deposits, cloudy water.
struct LSICalculator {

    // MARK: - LSI Result

    struct LSIResult {
        let lsiValue: Double
        let temperatureFactor: Double
        let calciumFactor: Double
        let alkalinityFactor: Double
        let pH: Double
        let tdsFactor: Double

        var status: WaterCondition {
            if lsiValue < -0.3 {
                return .corrosive
            } else if lsiValue > 0.3 {
                return .scaleForming
            } else {
                return .balanced
            }
        }

        var deviationFromEquilibrium: Double {
            lsiValue - 0.0
        }
    }

    enum WaterCondition: String {
        case corrosive = "Corrosive"
        case balanced = "Balanced"
        case scaleForming = "Scale-Forming"

        var emoji: String {
            switch self {
            case .corrosive: return "⚠️"
            case .balanced: return "✅"
            case .scaleForming: return "🔶"
            }
        }

        var description: String {
            switch self {
            case .corrosive:
                return "Water is aggressive — dissolves plaster, corrodes equipment, etches surfaces."
            case .balanced:
                return "Water is balanced — no significant scaling or corrosion tendency."
            case .scaleForming:
                return "Water is scale-forming — calcium deposits, cloudy water, clogged heaters."
            }
        }
    }

    // MARK: - Temperature Factor Table
    // Maps water temperature (°F) to the temperature factor (TF).
    // Source: Standard Langelier tables used in pool/water treatment industry.

    static let temperatureFactorTable: [(tempF: Double, factor: Double)] = [
        (32,  0.0),
        (37,  0.1),
        (46,  0.2),
        (53,  0.3),
        (60,  0.4),
        (66,  0.5),
        (76,  0.6),
        (84,  0.7),
        (94,  0.8),
        (105, 0.9),
    ]

    // MARK: - Calcium Hardness Factor Table
    // Maps Calcium Hardness (ppm as CaCO3) to the calcium factor (CF).

    static let calciumFactorTable: [(ppm: Double, factor: Double)] = [
        (5,    0.3),
        (25,   1.0),
        (50,   1.3),
        (75,   1.5),
        (100,  1.6),
        (150,  1.8),
        (200,  1.9),
        (250,  2.0),
        (300,  2.1),
        (400,  2.2),
        (500,  2.3),
        (600,  2.35),
        (800,  2.5),
        (1000, 2.6),
    ]

    // MARK: - Alkalinity Factor Table
    // Maps Total Alkalinity (ppm as CaCO3) to the alkalinity factor (AF).

    static let alkalinityFactorTable: [(ppm: Double, factor: Double)] = [
        (5,    0.7),
        (25,   1.4),
        (50,   1.7),
        (75,   1.9),
        (100,  2.0),
        (125,  2.1),
        (150,  2.2),
        (200,  2.3),
        (250,  2.4),
        (300,  2.5),
        (400,  2.6),
        (500,  2.7),
        (600,  2.8),
        (800,  2.9),
        (1000, 3.0),
    ]

    // MARK: - TDS Correction Factor Table
    // Total Dissolved Solids affects the constant subtracted in the LSI formula.
    // Standard formula uses 12.1 for TDS ~1000 ppm. This table provides refinement.

    static let tdsFactorTable: [(ppm: Double, constant: Double)] = [
        (0,    12.27),
        (400,  12.23),
        (800,  12.15),
        (1000, 12.10),
        (1200, 12.05),
        (1500, 12.00),
        (2000, 11.92),
        (3000, 11.82),
        (4000, 11.74),
        (5000, 11.68),
    ]

    // MARK: - Interpolation

    /// Linearly interpolates a value from a sorted lookup table.
    /// If the input falls below the first entry, returns the first factor.
    /// If above the last entry, returns the last factor.
    static func interpolate(value: Double, table: [(Double, Double)]) -> Double {
        guard !table.isEmpty else { return 0.0 }

        // Below range
        if value <= table.first!.0 {
            return table.first!.1
        }
        // Above range
        if value >= table.last!.0 {
            return table.last!.1
        }

        // Find bracketing entries and interpolate
        for i in 0..<(table.count - 1) {
            let (lowKey, lowVal) = table[i]
            let (highKey, highVal) = table[i + 1]
            if value >= lowKey && value <= highKey {
                let fraction = (value - lowKey) / (highKey - lowKey)
                return lowVal + fraction * (highVal - lowVal)
            }
        }

        return table.last!.1
    }

    // MARK: - Factor Lookups

    static func temperatureFactor(tempF: Double) -> Double {
        interpolate(
            value: tempF,
            table: temperatureFactorTable.map { ($0.tempF, $0.factor) }
        )
    }

    static func calciumFactor(calciumHardness: Double) -> Double {
        interpolate(
            value: calciumHardness,
            table: calciumFactorTable.map { ($0.ppm, $0.factor) }
        )
    }

    static func alkalinityFactor(totalAlkalinity: Double) -> Double {
        interpolate(
            value: totalAlkalinity,
            table: alkalinityFactorTable.map { ($0.ppm, $0.factor) }
        )
    }

    static func tdsConstant(tds: Double) -> Double {
        interpolate(
            value: tds,
            table: tdsFactorTable.map { ($0.ppm, $0.constant) }
        )
    }

    // MARK: - Calculate LSI

    /// Calculates the Langelier Saturation Index.
    ///
    /// - Parameters:
    ///   - pH: Measured water pH (typically 6.8 - 8.2)
    ///   - waterTempF: Water temperature in Fahrenheit
    ///   - calciumHardness: Calcium hardness in ppm
    ///   - totalAlkalinity: Total alkalinity in ppm
    ///   - tds: Total dissolved solids in ppm (default 1000)
    /// - Returns: An `LSIResult` containing the index value and all factors.
    static func calculate(
        pH: Double,
        waterTempF: Double,
        calciumHardness: Double,
        totalAlkalinity: Double,
        tds: Double = 1000.0
    ) -> LSIResult {
        let tf = temperatureFactor(tempF: waterTempF)
        let cf = calciumFactor(calciumHardness: calciumHardness)
        let af = alkalinityFactor(totalAlkalinity: totalAlkalinity)
        let tdsC = tdsConstant(tds: tds)

        let lsi = pH + tf + cf + af - tdsC

        return LSIResult(
            lsiValue: lsi,
            temperatureFactor: tf,
            calciumFactor: cf,
            alkalinityFactor: af,
            pH: pH,
            tdsFactor: tdsC
        )
    }

    /// Convenience: calculate directly from a Pool model.
    static func calculate(for pool: Pool) -> LSIResult {
        calculate(
            pH: pool.pH,
            waterTempF: pool.waterTempF,
            calciumHardness: pool.calciumHardness,
            totalAlkalinity: pool.totalAlkalinity,
            tds: pool.totalDissolvedSolids
        )
    }
}
