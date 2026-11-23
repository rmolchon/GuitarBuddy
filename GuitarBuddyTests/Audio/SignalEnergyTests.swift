import XCTest
@testable import GuitarBuddy

final class SignalEnergyTests: XCTestCase {
    func test_emptyBufferHasNoEnergy() {
        XCTAssertFalse(SignalEnergy.hasSufficientEnergy([], minimumRMS: 0.01))
    }

    func test_silenceIsBelowThreshold() {
        XCTAssertFalse(SignalEnergy.hasSufficientEnergy([Float](repeating: 0, count: 1024), minimumRMS: 0.01))
    }

    func test_loudSignalIsAboveThreshold() {
        XCTAssertTrue(SignalEnergy.hasSufficientEnergy([Float](repeating: 0.5, count: 1024), minimumRMS: 0.01))
    }

    func test_thresholdIsInclusive() {
        XCTAssertTrue(SignalEnergy.hasSufficientEnergy([Float](repeating: 0.25, count: 16), minimumRMS: 0.25))
    }
}
