import Foundation

/// Translates LSI deviations into specific, actionable chemical dosing recommendations.
///
/// Dosing is calculated per 10,000 gallons of pool water. The engine determines
/// which parameter to adjust first (pH is always the priority) and provides
/// fluid-ounce quantities a tech can measure on the truck.
struct DosingEngine {

    // MARK: - Dosing Recommendation

    struct DosingRecommendation: Identifiable {
        /// MED-3: Stable identity derived from content rather than random UUID.
        /// Prevents SwiftUI ForEach from destroying/recreating views on every recomputation.
        var id: String {
            "\(chemicalType.rawValue)-\(priority)"
        }
        let chemicalName: String
        let chemicalType: ChemicalType
        let quantityOz: Double
        let quantityLabel: String
        let instruction: String
        let priority: Int // 1 = do first
        let costPerOz: Double

        var estimatedCost: Double {
            quantityOz * costPerOz
        }
    }

    // MARK: - Cost Lookup

    /// Resolves the actual cost-per-oz from inventory, falling back to industry defaults.
    struct CostLookup {
        private let inventoryByType: [ChemicalType: Double]

        /// Default industry-average costs when no inventory is present.
        static let defaults: [ChemicalType: Double] = [
            .acid:       0.05,
            .base:       0.09,
            .calcium:    0.07,
            .alkalinity: 0.04,
            .chlorine:   0.02,
            .stabilizer: 0.12,
        ]

        init(inventory: [ChemicalInventory] = []) {
            var map: [ChemicalType: Double] = [:]
            for item in inventory {
                // Use the first matching item per type (cheapest-first would be a future upgrade)
                if map[item.chemicalType] == nil {
                    map[item.chemicalType] = item.costPerOz
                }
            }
            self.inventoryByType = map
        }

        func costPerOz(for type: ChemicalType) -> Double {
            inventoryByType[type] ?? Self.defaults[type] ?? 0.0
        }
    }

    // MARK: - Dosing Constants

    // Muriatic acid (31.45%) dosing: ~26 oz per 10,000 gal lowers pH by 0.2
    static let muriaticAcidOzPer10kGalPerPointTwoPH: Double = 26.0

    // Soda ash dosing: ~6 oz per 10,000 gal raises pH by 0.2
    static let sodaAshOzPer10kGalPerPointTwoPH: Double = 6.0

    // Sodium bicarb dosing: ~1.5 lbs (24 oz) per 10,000 gal raises TA by 10 ppm
    static let sodiumBicarbOzPer10kGalPer10ppmTA: Double = 24.0

    // Calcium chloride dosing: ~1.25 lbs (20 oz) per 10,000 gal raises CH by 10 ppm
    static let calciumChlorideOzPer10kGalPer10ppmCH: Double = 20.0

    // MARK: - Generate Recommendations

    /// Produces a prioritized list of dosing steps to bring the pool toward LSI equilibrium.
    ///
    /// Strategy:
    /// 1. If LSI is negative (corrosive): raise pH, then raise calcium/alkalinity.
    /// 2. If LSI is positive (scaling): lower pH, consider dilution for extreme calcium.
    /// 3. pH adjustment is always step 1 (fastest acting, most impactful).
    static func recommend(
        lsiResult: LSICalculator.LSIResult,
        currentPH: Double,
        currentTA: Double,
        currentCH: Double,
        poolVolumeGallons: Double,
        costs: CostLookup = CostLookup()
    ) -> [DosingRecommendation] {
        let volumeFactor = poolVolumeGallons / 10_000.0
        var recommendations: [DosingRecommendation] = []
        var priority = 1
        let deviation = lsiResult.lsiValue

        if lsiResult.status == .balanced {
            return [
                DosingRecommendation(
                    chemicalName: "None",
                    chemicalType: .none,
                    quantityOz: 0,
                    quantityLabel: "—",
                    instruction: "Water is balanced. No chemical adjustment needed.",
                    priority: 0,
                    costPerOz: 0
                )
            ]
        }

        if deviation < -0.3 {
            // --- CORROSIVE WATER: Need to raise LSI ---

            // Step 1: Raise pH if below 7.4
            if currentPH < 7.4 {
                let phDeficit = 7.4 - currentPH
                let incrementsNeeded = phDeficit / 0.2
                let ozNeeded = incrementsNeeded * sodaAshOzPer10kGalPerPointTwoPH * volumeFactor
                let rounded = ceilToNearest(ozNeeded, nearest: 1.0)

                recommendations.append(DosingRecommendation(
                    chemicalName: "Soda Ash (Sodium Carbonate)",
                    chemicalType: .base,
                    quantityOz: rounded,
                    quantityLabel: formatQuantity(rounded),
                    instruction: "Add \(formatQuantity(rounded)) of Soda Ash to raise pH from \(String(format: "%.1f", currentPH)) to 7.4",
                    priority: priority,
                    costPerOz: costs.costPerOz(for: .base)
                ))
                priority += 1
            }

            // Step 2: Raise alkalinity if below 80 ppm
            if currentTA < 80 {
                let taDeficit = 80.0 - currentTA
                let incrementsNeeded = taDeficit / 10.0
                let ozNeeded = incrementsNeeded * sodiumBicarbOzPer10kGalPer10ppmTA * volumeFactor
                let rounded = ceilToNearest(ozNeeded, nearest: 1.0)

                recommendations.append(DosingRecommendation(
                    chemicalName: "Sodium Bicarbonate (Baking Soda)",
                    chemicalType: .alkalinity,
                    quantityOz: rounded,
                    quantityLabel: formatQuantity(rounded),
                    instruction: "Add \(formatQuantity(rounded)) of Sodium Bicarbonate to raise alkalinity from \(Int(currentTA)) to 80 ppm",
                    priority: priority,
                    costPerOz: costs.costPerOz(for: .alkalinity)
                ))
                priority += 1
            }

            // Step 3: Raise calcium hardness if below 200 ppm
            if currentCH < 200 {
                let chDeficit = 200.0 - currentCH
                let incrementsNeeded = chDeficit / 10.0
                let ozNeeded = incrementsNeeded * calciumChlorideOzPer10kGalPer10ppmCH * volumeFactor
                let rounded = ceilToNearest(ozNeeded, nearest: 1.0)

                recommendations.append(DosingRecommendation(
                    chemicalName: "Calcium Chloride (Hardness Up)",
                    chemicalType: .calcium,
                    quantityOz: rounded,
                    quantityLabel: formatQuantity(rounded),
                    instruction: "Add \(formatQuantity(rounded)) of Calcium Chloride to raise hardness from \(Int(currentCH)) to 200 ppm",
                    priority: priority,
                    costPerOz: costs.costPerOz(for: .calcium)
                ))
                priority += 1
            }

        } else if deviation > 0.3 {
            // --- SCALE-FORMING WATER: Need to lower LSI ---

            // Step 1: Lower pH if above 7.6
            if currentPH > 7.6 {
                let phExcess = currentPH - 7.6
                let incrementsNeeded = phExcess / 0.2
                let ozNeeded = incrementsNeeded * muriaticAcidOzPer10kGalPerPointTwoPH * volumeFactor
                let rounded = ceilToNearest(ozNeeded, nearest: 1.0)

                recommendations.append(DosingRecommendation(
                    chemicalName: "Muriatic Acid (31.45%)",
                    chemicalType: .acid,
                    quantityOz: rounded,
                    quantityLabel: formatQuantity(rounded),
                    instruction: "Add \(formatQuantity(rounded)) of Muriatic Acid to lower pH from \(String(format: "%.1f", currentPH)) to 7.6",
                    priority: priority,
                    costPerOz: costs.costPerOz(for: .acid)
                ))
                priority += 1
            }

            // Step 2: Lower alkalinity if above 120 ppm (use acid — lowers both pH and TA)
            if currentTA > 120 && currentPH <= 7.6 {
                let taExcess = currentTA - 120.0
                let incrementsNeeded = taExcess / 10.0
                let ozNeeded = incrementsNeeded * muriaticAcidOzPer10kGalPerPointTwoPH * 0.5 * volumeFactor
                let rounded = ceilToNearest(ozNeeded, nearest: 1.0)

                recommendations.append(DosingRecommendation(
                    chemicalName: "Muriatic Acid (31.45%)",
                    chemicalType: .acid,
                    quantityOz: rounded,
                    quantityLabel: formatQuantity(rounded),
                    instruction: "Add \(formatQuantity(rounded)) of Muriatic Acid to lower alkalinity from \(Int(currentTA)) to 120 ppm, then aerate to restore pH",
                    priority: priority,
                    costPerOz: costs.costPerOz(for: .acid)
                ))
                priority += 1
            }

            // Step 3: Note about high calcium (can't chemically remove — partial drain)
            if currentCH > 400 {
                recommendations.append(DosingRecommendation(
                    chemicalName: "Partial Drain & Refill",
                    chemicalType: .dilution,
                    quantityOz: 0,
                    quantityLabel: "—",
                    instruction: "Calcium at \(Int(currentCH)) ppm is too high for chemical correction. Recommend partial drain and fresh water refill to dilute below 400 ppm.",
                    priority: priority,
                    costPerOz: 0.0
                ))
                priority += 1
            }
        }

        // Fallback: if no specific parameter is out of range but LSI is still off,
        // give a general pH nudge.
        if recommendations.isEmpty {
            if deviation < 0 {
                let nudgeOz = ceilToNearest(3.0 * volumeFactor, nearest: 1.0)
                recommendations.append(DosingRecommendation(
                    chemicalName: "Soda Ash (Sodium Carbonate)",
                    chemicalType: .base,
                    quantityOz: nudgeOz,
                    quantityLabel: formatQuantity(nudgeOz),
                    instruction: "Add \(formatQuantity(nudgeOz)) of Soda Ash to nudge pH up slightly. Retest in 4 hours.",
                    priority: 1,
                    costPerOz: costs.costPerOz(for: .base)
                ))
            } else {
                let nudgeOz = ceilToNearest(8.0 * volumeFactor, nearest: 1.0)
                recommendations.append(DosingRecommendation(
                    chemicalName: "Muriatic Acid (31.45%)",
                    chemicalType: .acid,
                    quantityOz: nudgeOz,
                    quantityLabel: formatQuantity(nudgeOz),
                    instruction: "Add \(formatQuantity(nudgeOz)) of Muriatic Acid to nudge pH down slightly. Retest in 4 hours.",
                    priority: 1,
                    costPerOz: costs.costPerOz(for: .acid)
                ))
            }
        }

        return recommendations.sorted { $0.priority < $1.priority }
    }

    /// Convenience: generate recommendations directly from a Pool model.
    static func recommend(for pool: Pool, costs: CostLookup = CostLookup()) -> [DosingRecommendation] {
        let lsi = LSICalculator.calculate(for: pool)
        return recommend(
            lsiResult: lsi,
            currentPH: pool.pH,
            currentTA: pool.totalAlkalinity,
            currentCH: pool.calciumHardness,
            poolVolumeGallons: pool.poolVolumeGallons,
            costs: costs
        )
    }

    // MARK: - Helpers

    static func ceilToNearest(_ value: Double, nearest: Double) -> Double {
        (value / nearest).rounded(.up) * nearest
    }

    /// Formats ounce quantities into human-readable measurements.
    /// < 16 oz: show as "X oz"
    /// 16-127 oz: show as "X lbs Y oz" (dry) or pints/quarts (liquid)
    /// >= 128 oz: show as gallons
    static func formatQuantity(_ oz: Double) -> String {
        if oz <= 0 { return "—" }
        if oz < 16 {
            return "\(Int(oz)) oz"
        } else if oz < 128 {
            let lbs = Int(oz) / 16
            let remainder = Int(oz) % 16
            if remainder == 0 {
                return "\(lbs) lb\(lbs > 1 ? "s" : "")"
            } else {
                return "\(lbs) lb\(lbs > 1 ? "s" : "") \(remainder) oz"
            }
        } else {
            let gallons = oz / 128.0
            return String(format: "%.1f gal", gallons)
        }
    }

    // MARK: - Profit Calculation

    /// Calculates profit-per-pool based on service fee vs chemical costs over a billing period.
    static func profitAnalysis(
        monthlyFee: Double,
        serviceEvents: [ServiceEvent],
        billingPeriodDays: Int = 30
    ) -> (totalChemCost: Double, profit: Double, isInTheRed: Bool) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -billingPeriodDays, to: Date()) ?? Date()
        let recentEvents = serviceEvents.filter { $0.timestamp >= cutoff }
        let totalChemCost = recentEvents.reduce(0.0) { $0 + $1.totalChemicalCost }
        let profit = monthlyFee - totalChemCost
        return (totalChemCost, profit, profit < 0)
    }
}
