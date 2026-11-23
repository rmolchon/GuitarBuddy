import XCTest
@testable import GuitarBuddy

final class PitchSmootherTests: XCTestCase {
    func test_firstReadingPassesThrough() {
        var smoother = PitchSmoother(windowSize: 5, holdFrames: 3)
        XCTAssertEqual(smoother.push(110.0), 110.0)
    }

    func test_returnsMedianOfRecentReadings() {
        var smoother = PitchSmoother(windowSize: 3, holdFrames: 3)
        _ = smoother.push(110.0)
        _ = smoother.push(112.0)
        XCTAssertEqual(smoother.push(111.0), 111.0)
    }

    func test_singleOutlierIsRejected() {
        var smoother = PitchSmoother(windowSize: 3, holdFrames: 3)
        _ = smoother.push(110.0)
        _ = smoother.push(110.5)
        // An octave-error blip must not move the output.
        XCTAssertEqual(smoother.push(220.0), 110.5)
    }

    func test_windowSlidesSoOldReadingsAgeOut() {
        var smoother = PitchSmoother(windowSize: 3, holdFrames: 3)
        _ = smoother.push(100.0)
        _ = smoother.push(200.0)
        _ = smoother.push(200.0)
        XCTAssertEqual(smoother.push(200.0), 200.0)
    }

    func test_evenWindowAveragesMiddleTwo() {
        var smoother = PitchSmoother(windowSize: 4, holdFrames: 3)
        _ = smoother.push(100.0)
        XCTAssertEqual(smoother.push(110.0), 105.0)
    }

    func test_shortDropoutHoldsLastValue() {
        var smoother = PitchSmoother(windowSize: 3, holdFrames: 2)
        _ = smoother.push(110.0)
        XCTAssertEqual(smoother.push(nil), 110.0)
        XCTAssertEqual(smoother.push(nil), 110.0)
    }

    func test_sustainedSilenceReturnsNil() {
        var smoother = PitchSmoother(windowSize: 3, holdFrames: 2)
        _ = smoother.push(110.0)
        _ = smoother.push(nil)
        _ = smoother.push(nil)
        XCTAssertNil(smoother.push(nil))
    }

    func test_silenceBeforeAnyReadingReturnsNil() {
        var smoother = PitchSmoother(windowSize: 3, holdFrames: 2)
        XCTAssertNil(smoother.push(nil))
    }

    func test_readingAfterSilenceIsNotBlendedWithOldWindow() {
        var smoother = PitchSmoother(windowSize: 5, holdFrames: 1)
        _ = smoother.push(110.0)
        _ = smoother.push(110.0)
        _ = smoother.push(nil)
        _ = smoother.push(nil)
        XCTAssertEqual(smoother.push(220.0), 220.0)
    }

    func test_dropoutResetsConsecutiveMissCount() {
        var smoother = PitchSmoother(windowSize: 3, holdFrames: 1)
        _ = smoother.push(110.0)
        _ = smoother.push(nil)
        _ = smoother.push(110.0)
        XCTAssertEqual(smoother.push(nil), 110.0)
    }
}
