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

    // MARK: - Haptics

    #if canImport(UIKit)
    static func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func hapticWarning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    static func hapticError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    static func hapticLight() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func hapticMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
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
