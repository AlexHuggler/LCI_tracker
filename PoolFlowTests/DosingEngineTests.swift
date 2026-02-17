import Testing
@testable import PoolFlow

/// Tests for DosingEngine — validates MED-3 (stable identity),
/// dosing correctness, and cost calculation.
struct DosingEngineTests {

    // MARK: - MED-3: Stable Recommendation Identity

    @Test("Recommendation IDs are stable across recomputations")
    func stableRecommendationIdentity() {
        let costs = DosingEngine.CostLookup()
        let lsi = LSICalculator.calculate(
            pH: 6.8, waterTempF: 78.0,
            calciumHardness: 150.0, totalAlkalinity: 60.0, tds: 800.0
        )

        let first = DosingEngine.recommend(
            lsiResult: lsi, currentPH: 6.8,
            currentTA: 60.0, currentCH: 150.0,
            poolVolumeGallons: 15000, costs: costs
        )
        let second = DosingEngine.recommend(
            lsiResult: lsi, currentPH: 6.8,
            currentTA: 60.0, currentCH: 150.0,
            poolVolumeGallons: 15000, costs: costs
        )

        // Same inputs → same IDs (content-based, not random UUID)
        #expect(first.count == second.count)
        for (a, b) in zip(first, second) {
            #expect(a.id == b.id)
        }
    }

    @Test("Recommendation ID changes when chemical type changes")
    func recommendationIdentityChangesWithContent() {
        let costs = DosingEngine.CostLookup()

        // Corrosive → needs base
        let corrosiveLSI = LSICalculator.calculate(
            pH: 6.5, waterTempF: 60.0,
            calciumHardness: 100.0, totalAlkalinity: 40.0, tds: 500.0
        )
        let corrosiveRecs = DosingEngine.recommend(
            lsiResult: corrosiveLSI, currentPH: 6.5,
            currentTA: 40.0, currentCH: 100.0,
            poolVolumeGallons: 15000, costs: costs
        )

        // Scale-forming → needs acid
        let scaleLSI = LSICalculator.calculate(
            pH: 8.5, waterTempF: 100.0,
            calciumHardness: 800.0, totalAlkalinity: 200.0, tds: 2000.0
        )
        let scaleRecs = DosingEngine.recommend(
            lsiResult: scaleLSI, currentPH: 8.5,
            currentTA: 200.0, currentCH: 800.0,
            poolVolumeGallons: 15000, costs: costs
        )

        // Different water conditions should produce different recommendation IDs
        if let firstCorrosive = corrosiveRecs.first, let firstScale = scaleRecs.first {
            #expect(firstCorrosive.id != firstScale.id)
        }
    }

    // MARK: - Dosing Correctness

    @Test("Corrosive water recommends raising pH first")
    func corrosiveWaterRecommendation() {
        let costs = DosingEngine.CostLookup()
        let lsi = LSICalculator.calculate(
            pH: 6.8, waterTempF: 78.0,
            calciumHardness: 200.0, totalAlkalinity: 80.0, tds: 1000.0
        )
        let recs = DosingEngine.recommend(
            lsiResult: lsi, currentPH: 6.8,
            currentTA: 80.0, currentCH: 200.0,
            poolVolumeGallons: 15000, costs: costs
        )

        #expect(!recs.isEmpty)
        #expect(recs[0].priority == 1)
        // First recommendation should be to raise pH (soda ash = base type)
        #expect(recs[0].chemicalType == .base)
    }

    @Test("Scale-forming water recommends lowering pH first")
    func scaleFormingWaterRecommendation() {
        let costs = DosingEngine.CostLookup()
        let lsi = LSICalculator.calculate(
            pH: 8.2, waterTempF: 85.0,
            calciumHardness: 500.0, totalAlkalinity: 150.0, tds: 1500.0
        )
        let recs = DosingEngine.recommend(
            lsiResult: lsi, currentPH: 8.2,
            currentTA: 150.0, currentCH: 500.0,
            poolVolumeGallons: 15000, costs: costs
        )

        #expect(!recs.isEmpty)
        #expect(recs[0].priority == 1)
        // First recommendation should be to lower pH (muriatic acid = acid type)
        #expect(recs[0].chemicalType == .acid)
    }

    @Test("Balanced water produces no recommendations")
    func balancedWaterNoRecommendations() {
        let costs = DosingEngine.CostLookup()
        let lsi = LSICalculator.calculate(
            pH: 7.4, waterTempF: 78.0,
            calciumHardness: 300.0, totalAlkalinity: 100.0, tds: 1000.0
        )
        let recs = DosingEngine.recommend(
            lsiResult: lsi, currentPH: 7.4,
            currentTA: 100.0, currentCH: 300.0,
            poolVolumeGallons: 15000, costs: costs
        )

        #expect(recs.isEmpty)
    }

    // MARK: - Cost Calculation

    @Test("Estimated cost equals quantity times cost per oz")
    func estimatedCostCalculation() {
        let costs = DosingEngine.CostLookup()
        let lsi = LSICalculator.calculate(
            pH: 6.8, waterTempF: 78.0,
            calciumHardness: 200.0, totalAlkalinity: 80.0, tds: 1000.0
        )
        let recs = DosingEngine.recommend(
            lsiResult: lsi, currentPH: 6.8,
            currentTA: 80.0, currentCH: 200.0,
            poolVolumeGallons: 15000, costs: costs
        )

        for rec in recs {
            let expected = rec.quantityOz * rec.costPerOz
            #expect(abs(rec.estimatedCost - expected) < 0.001)
        }
    }

    @Test("CostLookup falls back to defaults when inventory is empty")
    func costLookupDefaults() {
        let costs = DosingEngine.CostLookup()
        let acidCost = costs.costPerOz(for: .acid)
        #expect(acidCost > 0)
        #expect(acidCost == DosingEngine.CostLookup.defaults[.acid])
    }

    // MARK: - Profit Analysis

    @Test("Profit analysis with no events returns full fee as profit")
    func profitAnalysisNoEvents() {
        let result = DosingEngine.profitAnalysis(
            monthlyFee: 150.0,
            serviceEvents: []
        )
        #expect(result.totalChemCost == 0.0)
        #expect(result.profit == 150.0)
        #expect(result.isInTheRed == false)
    }

    // MARK: - Quantity Formatting

    @Test("formatQuantity handles oz, lbs, and gallon conversions")
    func quantityFormatting() {
        let small = DosingEngine.formatQuantity(8.0)
        #expect(small.contains("8"))

        let onePound = DosingEngine.formatQuantity(16.0)
        #expect(onePound.contains("lb"))

        let oneGallon = DosingEngine.formatQuantity(128.0)
        #expect(oneGallon.contains("gal"))
    }
}
