import XCTest
@testable import GuitarBuddy

final class TuningTests: XCTestCase {
    func test_standardTuningHasSixStringsLowToHigh() {
        // Arrange
        let tuning = Tuning.standard
        // Act
        let frequencies = tuning.stringFrequencies
        // Assert
        XCTAssertEqual(tuning.name, "Standard")
        XCTAssertEqual(frequencies, [82.41, 110.00, 146.83, 196.00, 246.94, 329.63])
    }

    func test_dropDLowersOnlyTheLowestString() {
        let tuning = Tuning.dropD
        XCTAssertEqual(tuning.name, "Drop D")
        XCTAssertEqual(tuning.stringFrequencies, [73.42, 110.00, 146.83, 196.00, 246.94, 329.63])
    }

    func test_openGFrequencies() {
        let tuning = Tuning.openG
        XCTAssertEqual(tuning.name, "Open G")
        XCTAssertEqual(tuning.stringFrequencies, [73.42, 98.00, 146.83, 196.00, 246.94, 293.66])
    }

    func test_openDFrequencies() {
        let tuning = Tuning.openD
        XCTAssertEqual(tuning.name, "Open D")
        XCTAssertEqual(tuning.stringFrequencies, [73.42, 110.00, 146.83, 185.00, 220.00, 293.66])
    }

    func test_dadgadFrequencies() {
        let tuning = Tuning.dadgad
        XCTAssertEqual(tuning.name, "DADGAD")
        XCTAssertEqual(tuning.stringFrequencies, [73.42, 110.00, 146.83, 196.00, 220.00, 293.66])
    }

    func test_halfStepDownFrequencies() {
        let tuning = Tuning.halfStepDown
        XCTAssertEqual(tuning.name, "Half-Step Down")
        XCTAssertEqual(tuning.stringFrequencies, [77.78, 103.83, 138.59, 185.00, 233.08, 311.13])
    }

    func test_allPresetsContainsEveryPresetInOrder() {
        XCTAssertEqual(Tuning.allPresets, [
            .standard, .dropD, .openG, .openD, .dadgad, .halfStepDown
        ])
    }

    func test_everyPresetHasSixStrings() {
        for tuning in Tuning.allPresets {
            XCTAssertEqual(tuning.stringFrequencies.count, 6, "\(tuning.name) should have 6 strings")
        }
    }
}
