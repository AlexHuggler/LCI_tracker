import Foundation
import SwiftUI
import SwiftData

/// ViewModel for the pool list / route view.
/// Manages filtering by service day and route reordering.
@Observable
final class PoolListViewModel {
    var selectedDayOfWeek: Int

    init() {
        // Default to today's day of week (1 = Sunday in Calendar)
        self.selectedDayOfWeek = Calendar.current.component(.weekday, from: Date())
    }

    /// Reorder pools after a drag-and-drop move.
    func movePool(from source: IndexSet, to destination: Int, in pools: [Pool]) {
        var reordered = pools
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, pool) in reordered.enumerated() {
            pool.routeOrder = index
        }
    }

    /// Descriptive label for the currently selected day.
    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        // Calendar weekday symbols are 0-indexed; our model uses 1-indexed
        let symbols = formatter.weekdaySymbols ?? []
        guard selectedDayOfWeek >= 1, selectedDayOfWeek <= symbols.count else {
            return "Unknown"
        }
        return symbols[selectedDayOfWeek - 1]
    }
}
