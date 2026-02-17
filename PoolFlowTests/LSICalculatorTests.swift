import Testing
@testable import PoolFlow

/// Tests for LSICalculator — validates CRIT-1 (force unwrap removal),
/// HIGH-6 (WaterCondition.from), and MED-2 (Hashable/Codable conformance).
struct LSICalculatorTests {

    // MARK: - CRIT-1: Interpolation Safety

    @Test("Interpolation returns 0 for empty table")
    func interpolateEmptyTable() {
        let result = LSICalculator.interpolate(value: 50.0, table: [])
        #expect(result == 0.0)
    }

    @Test("Interpolation handles single-element table without crashing")
    func interpolateSingleElement() {
        let table: [(Double, Double)] = [(100.0, 2.0)]
        // Below the single entry
        #expect(LSICalculator.interpolate(value: 50.0, table: table) == 2.0)
        // Exact match
        #expect(LSICalculator.interpolate(value: 100.0, table: table) == 2.0)
        // Above the single entry
        #expect(LSICalculator.interpolate(value: 200.0, table: table) == 2.0)
    }

    @Test("Interpolation clamps below minimum")
    func interpolateBelowMin() {
        let table: [(Double, Double)] = [(32.0, 0.0), (100.0, 1.8)]
        let result = LSICalculator.interpolate(value: 0.0, table: table)
        #expect(result == 0.0)
    }

    @Test("Interpolation clamps above maximum")
    func interpolateAboveMax() {
        let table: [(Double, Double)] = [(32.0, 0.0), (100.0, 1.8)]
        let result = LSICalculator.interpolate(value: 999.0, table: table)
        #expect(result == 1.8)
    }

    @Test("Interpolation correctly interpolates midpoint")
    func interpolateMidpoint() {
        let table: [(Double, Double)] = [(0.0, 0.0), (100.0, 10.0)]
        let result = LSICalculator.interpolate(value: 50.0, table: table)
        #expect(result == 5.0)
    }

    @Test("Interpolation returns exact value at table entry")
    func interpolateExactMatch() {
        let table: [(Double, Double)] = [(0.0, 1.0), (50.0, 5.0), (100.0, 10.0)]
        let result = LSICalculator.interpolate(value: 50.0, table: table)
        #expect(result == 5.0)
    }

    // MARK: - LSI Calculation

    @Test("Balanced water produces LSI near zero")
    func balancedWater() {
        let result = LSICalculator.calculate(
            pH: 7.4,
            waterTempF: 78.0,
            calciumHardness: 300.0,
            totalAlkalinity: 100.0,
            tds: 1000.0
        )
        #expect(result.lsiValue > -0.5 && result.lsiValue < 0.5)
        #expect(result.status == .balanced)
    }

    @Test("Low pH produces corrosive LSI")
    func corrosiveWater() {
        let result = LSICalculator.calculate(
            pH: 6.5,
            waterTempF: 60.0,
            calciumHardness: 100.0,
            totalAlkalinity: 40.0,
            tds: 500.0
        )
        #expect(result.lsiValue < -0.3)
        #expect(result.status == .corrosive)
    }

    @Test("High pH + high calcium produces scale-forming LSI")
    func scaleFormingWater() {
        let result = LSICalculator.calculate(
            pH: 8.5,
            waterTempF: 100.0,
            calciumHardness: 800.0,
            totalAlkalinity: 200.0,
            tds: 2000.0
        )
        #expect(result.lsiValue > 0.3)
        #expect(result.status == .scaleForming)
    }

    // MARK: - HIGH-6 + MED-2: WaterCondition

    @Test("WaterCondition.from resolves correctly at boundaries")
    func waterConditionFromLSI() {
        #expect(LSICalculator.WaterCondition.from(lsiValue: -0.5) == .corrosive)
        #expect(LSICalculator.WaterCondition.from(lsiValue: -0.3) == .balanced)
        #expect(LSICalculator.WaterCondition.from(lsiValue: 0.0) == .balanced)
        #expect(LSICalculator.WaterCondition.from(lsiValue: 0.3) == .balanced)
        #expect(LSICalculator.WaterCondition.from(lsiValue: 0.31) == .scaleForming)
        #expect(LSICalculator.WaterCondition.from(lsiValue: -0.31) == .corrosive)
    }

    @Test("WaterCondition.from matches LSIResult.status")
    func waterConditionConsistentWithResult() {
        let result = LSICalculator.calculate(
            pH: 7.4, waterTempF: 78.0,
            calciumHardness: 300.0, totalAlkalinity: 100.0, tds: 1000.0
        )
        let direct = LSICalculator.WaterCondition.from(lsiValue: result.lsiValue)
        #expect(direct == result.status)
    }

    @Test("WaterCondition conforms to Hashable — usable as dictionary key")
    func waterConditionHashable() {
        var dict: [LSICalculator.WaterCondition: String] = [:]
        dict[.corrosive] = "blue"
        dict[.balanced] = "green"
        dict[.scaleForming] = "orange"
        #expect(dict.count == 3)
        #expect(dict[.balanced] == "green")
    }
}
