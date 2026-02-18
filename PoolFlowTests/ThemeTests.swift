import Testing
@testable import PoolFlow

/// Tests for Theme — validates chemistry range evaluation (C6)
/// and reading status color/label consistency.
struct ThemeTests {

    // MARK: - Chemistry Range Evaluation (C6)

    @Test("pH status: low below 7.2, ideal 7.2-7.8, high above 7.8")
    func pHRanges() {
        #expect(Theme.pHStatus(6.0) == .low)
        #expect(Theme.pHStatus(7.0) == .low)
        #expect(Theme.pHStatus(7.2) == .ideal)
        #expect(Theme.pHStatus(7.5) == .ideal)
        #expect(Theme.pHStatus(7.8) == .ideal)
        #expect(Theme.pHStatus(8.0) == .high)
        #expect(Theme.pHStatus(9.0) == .high)
    }

    @Test("Calcium status: low below 200, ideal 200-400, high above 400")
    func calciumRanges() {
        #expect(Theme.calciumStatus(100) == .low)
        #expect(Theme.calciumStatus(199) == .low)
        #expect(Theme.calciumStatus(200) == .ideal)
        #expect(Theme.calciumStatus(300) == .ideal)
        #expect(Theme.calciumStatus(400) == .ideal)
        #expect(Theme.calciumStatus(401) == .high)
        #expect(Theme.calciumStatus(800) == .high)
    }

    @Test("Alkalinity status: low below 80, ideal 80-120, high above 120")
    func alkalinityRanges() {
        #expect(Theme.alkalinityStatus(40) == .low)
        #expect(Theme.alkalinityStatus(79) == .low)
        #expect(Theme.alkalinityStatus(80) == .ideal)
        #expect(Theme.alkalinityStatus(100) == .ideal)
        #expect(Theme.alkalinityStatus(120) == .ideal)
        #expect(Theme.alkalinityStatus(121) == .high)
        #expect(Theme.alkalinityStatus(200) == .high)
    }

    @Test("Temperature status: low below 60, ideal 60-90, high above 90")
    func tempRanges() {
        #expect(Theme.tempStatus(50) == .low)
        #expect(Theme.tempStatus(59) == .low)
        #expect(Theme.tempStatus(60) == .ideal)
        #expect(Theme.tempStatus(78) == .ideal)
        #expect(Theme.tempStatus(90) == .ideal)
        #expect(Theme.tempStatus(91) == .high)
        #expect(Theme.tempStatus(105) == .high)
    }

    // MARK: - Reading Status Labels

    @Test("Reading status labels are correct")
    func statusLabels() {
        #expect(Theme.readingStatusLabel(.low) == "Low")
        #expect(Theme.readingStatusLabel(.ideal) == "Ideal")
        #expect(Theme.readingStatusLabel(.high) == "High")
    }

    // MARK: - Edge Cases

    @Test("Boundary values are classified as ideal, not out-of-range")
    func boundaryClassification() {
        // pH exactly at boundary
        #expect(Theme.pHStatus(7.2) == .ideal)
        #expect(Theme.pHStatus(7.8) == .ideal)

        // Calcium exactly at boundary
        #expect(Theme.calciumStatus(200) == .ideal)
        #expect(Theme.calciumStatus(400) == .ideal)

        // Alkalinity exactly at boundary
        #expect(Theme.alkalinityStatus(80) == .ideal)
        #expect(Theme.alkalinityStatus(120) == .ideal)

        // Temperature exactly at boundary
        #expect(Theme.tempStatus(60) == .ideal)
        #expect(Theme.tempStatus(90) == .ideal)
    }
}
