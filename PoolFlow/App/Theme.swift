import SwiftUI

/// Single source of truth for all visual constants.
/// Eliminates duplicated color switches across views and ensures
/// consistent sizing for the "One-Tap Rule" (gloved/wet hands).
enum Theme {

    // MARK: - Touch Targets

    static let minTouchTarget: CGFloat = 44
    static let buttonHeight: CGFloat = 56
    static let cornerRadius: CGFloat = 14
    static let cardCornerRadius: CGFloat = 16
    static let tileCornerRadius: CGFloat = 12

    // MARK: - LSI Status Colors

    static func lsiColor(for status: LSICalculator.WaterCondition) -> Color {
        switch status {
        case .corrosive:    return .blue
        case .balanced:     return .green
        case .scaleForming: return .orange
        }
    }

    // MARK: - Chemical Type Colors

    static func chemicalColor(for type: ChemicalType) -> Color {
        switch type {
        case .acid:       return .red
        case .base:       return .blue
        case .calcium:    return .cyan
        case .alkalinity: return .teal
        case .chlorine:   return .yellow
        case .stabilizer: return .indigo
        case .dilution:   return .orange
        case .none:       return .gray
        }
    }

    // MARK: - Slider Tints

    static func sliderTint(for label: String) -> Color {
        switch label {
        case "pH":         return .purple
        case "Temp":       return .red
        case "Calcium":    return .cyan
        case "Alkalinity": return .teal
        default:           return .gray
        }
    }

    // MARK: - Background Tint Opacity

    static let badgeTintOpacity: Double = 0.15
    static let cardTintOpacity: Double = 0.08

    // MARK: - Chemistry Ideal Ranges (C6)

    enum ReadingStatus {
        case low, ideal, high
    }

    static func pHStatus(_ value: Double) -> ReadingStatus {
        if value < 7.2 { return .low }
        if value > 7.8 { return .high }
        return .ideal
    }

    static func calciumStatus(_ value: Double) -> ReadingStatus {
        if value < 200 { return .low }
        if value > 400 { return .high }
        return .ideal
    }

    static func alkalinityStatus(_ value: Double) -> ReadingStatus {
        if value < 80 { return .low }
        if value > 120 { return .high }
        return .ideal
    }

    static func tempStatus(_ value: Double) -> ReadingStatus {
        if value < 60 { return .low }
        if value > 90 { return .high }
        return .ideal
    }

    static func readingStatusColor(_ status: ReadingStatus) -> Color {
        switch status {
        case .low:   return .blue
        case .ideal: return .green
        case .high:  return .orange
        }
    }

    static func readingStatusLabel(_ status: ReadingStatus) -> String {
        switch status {
        case .low:   return "Low"
        case .ideal: return "Ideal"
        case .high:  return "High"
        }
    }

    // MARK: - Haptics (B5: Pre-warmed generators)

    #if canImport(UIKit)
    private static let notificationGenerator: UINotificationFeedbackGenerator = {
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        return gen
    }()

    private static let lightImpactGenerator: UIImpactFeedbackGenerator = {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        return gen
    }()

    private static let mediumImpactGenerator: UIImpactFeedbackGenerator = {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.prepare()
        return gen
    }()

    static func hapticSuccess() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    static func hapticWarning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    static func hapticError() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    static func hapticLight() {
        lightImpactGenerator.impactOccurred()
        lightImpactGenerator.prepare()
    }

    static func hapticMedium() {
        mediumImpactGenerator.impactOccurred()
        mediumImpactGenerator.prepare()
    }

    static func haptic(for status: LSICalculator.WaterCondition) {
        switch status {
        case .balanced:     hapticSuccess()
        case .scaleForming: hapticWarning()
        case .corrosive:    hapticError()
        }
    }
    #endif
}
