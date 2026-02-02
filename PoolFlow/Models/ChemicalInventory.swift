import Foundation
import SwiftData

/// Represents a chemical product the operator carries on the truck.
/// Tracks cost-per-unit for profit calculations and provides
/// the link between dosing recommendations and actual products.
@Model
final class ChemicalInventory {
    var id: UUID
    var name: String
    var chemicalType: String // "acid", "base", "calcium", "alkalinity", "chlorine", "stabilizer"
    var costPerOz: Double
    var currentStockOz: Double
    var unitLabel: String // "oz", "lbs", "gallons"
    var concentration: Double // percentage, e.g. 31.45 for muriatic acid

    @Relationship(deleteRule: .nullify, inverse: \ChemicalDose.chemical)
    var doses: [ChemicalDose] = []

    init(
        name: String,
        chemicalType: String,
        costPerOz: Double,
        currentStockOz: Double = 0.0,
        unitLabel: String = "oz",
        concentration: Double = 100.0
    ) {
        self.id = UUID()
        self.name = name
        self.chemicalType = chemicalType
        self.costPerOz = costPerOz
        self.currentStockOz = currentStockOz
        self.unitLabel = unitLabel
        self.concentration = concentration
    }
}

// MARK: - Default Chemical Catalog

extension ChemicalInventory {
    /// Seed data for common pool chemicals with typical retail pricing.
    static func defaultCatalog() -> [ChemicalInventory] {
        [
            ChemicalInventory(
                name: "Muriatic Acid (31.45%)",
                chemicalType: "acid",
                costPerOz: 0.05,
                currentStockOz: 256.0, // 2 gallons
                unitLabel: "oz",
                concentration: 31.45
            ),
            ChemicalInventory(
                name: "Soda Ash (Sodium Carbonate)",
                chemicalType: "base",
                costPerOz: 0.09,
                currentStockOz: 160.0, // 10 lbs
                unitLabel: "oz",
                concentration: 100.0
            ),
            ChemicalInventory(
                name: "Calcium Chloride (Hardness Up)",
                chemicalType: "calcium",
                costPerOz: 0.07,
                currentStockOz: 400.0, // 25 lbs
                unitLabel: "oz",
                concentration: 77.0
            ),
            ChemicalInventory(
                name: "Sodium Bicarbonate (Alkalinity Up)",
                chemicalType: "alkalinity",
                costPerOz: 0.04,
                currentStockOz: 320.0, // 20 lbs
                unitLabel: "oz",
                concentration: 100.0
            ),
            ChemicalInventory(
                name: "Trichlor Tabs (Stabilized Chlorine)",
                chemicalType: "chlorine",
                costPerOz: 0.18,
                currentStockOz: 400.0, // 25 lbs
                unitLabel: "oz",
                concentration: 90.0
            ),
            ChemicalInventory(
                name: "Liquid Chlorine (12.5% Sodium Hypochlorite)",
                chemicalType: "chlorine",
                costPerOz: 0.02,
                currentStockOz: 512.0, // 4 gallons
                unitLabel: "oz",
                concentration: 12.5
            ),
            ChemicalInventory(
                name: "Cyanuric Acid (Stabilizer)",
                chemicalType: "stabilizer",
                costPerOz: 0.12,
                currentStockOz: 64.0, // 4 lbs
                unitLabel: "oz",
                concentration: 100.0
            ),
        ]
    }
}
