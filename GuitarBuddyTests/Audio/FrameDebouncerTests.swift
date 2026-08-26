import XCTest
@testable import GuitarBuddy

final class FrameDebouncerTests: XCTestCase {
    func test_sustainedSameValueAcrossManyFramesEmitsExactlyOneEvent() {
        // Arrange
        let debouncer = FrameDebouncer<Int>(areEqual: ==)
        // Act
        let events = [1, 1, 1, 1, 1].compactMap { debouncer.process($0) }
        // Assert
        XCTAssertEqual(events, [1])
    }

    func test_valueChangeHeldLongEnoughEmitsTwoEvents() {
        // Arrange
        let debouncer = FrameDebouncer<Int>(areEqual: ==)
        // Act
        let events = [1, 1, 2, 2, 2].compactMap { debouncer.process($0) }
        // Assert
        XCTAssertEqual(events, [1, 2])
    }

    func test_singleFrameBlipThatRevertsEmitsNoEvent() {
        // Arrange
        let debouncer = FrameDebouncer<Int>(areEqual: ==)
        // Act
        let events = [1, 1, 2, 1, 1].compactMap { debouncer.process($0) }
        // Assert
        XCTAssertEqual(events, [1])
    }

    func test_nilGapBetweenIdenticalValuesReArmsAndEmitsTwoEvents() {
        // Arrange
        let debouncer = FrameDebouncer<Int>(areEqual: ==)
        // Act
        let events = [1, 1, nil, nil, 1, 1].compactMap { debouncer.process($0) }
        // Assert
        XCTAssertEqual(events, [1, 1])
    }

    func test_allNilStreamEmitsNoEvents() {
        // Arrange
        let debouncer = FrameDebouncer<Int>(areEqual: ==)
        // Act
        let events: [Int] = [nil, nil, nil].compactMap { (value: Int?) in debouncer.process(value) }
        // Assert
        XCTAssertTrue(events.isEmpty)
    }

    func test_fewerThanDebounceThresholdFramesOfNewValueEmitsNoEventYet() {
        // Arrange
        let debouncer = FrameDebouncer<Int>(areEqual: ==)
        // Act
        let events = [1].compactMap { debouncer.process($0) }
        // Assert
        XCTAssertTrue(events.isEmpty)
    }

    func test_customEqualityClosureIsUsedForMatching() {
        // Arrange: equality only on absolute value, ignoring sign
        let debouncer = FrameDebouncer<Int>(areEqual: { abs($0) == abs($1) })
        // Act
        let events = [1, -1, -1].compactMap { debouncer.process($0) }
        // Assert: -1 matches under this equality, so it confirms as one event carrying -1, not a second event
        XCTAssertEqual(events, [-1])
    }

    func test_customRequiredConsecutiveFramesThreshold() {
        // Arrange
        let debouncer = FrameDebouncer<Int>(requiredConsecutiveFrames: 3, areEqual: ==)
        // Act
        let eventsAfterTwo = [1, 1].compactMap { debouncer.process($0) }
        let eventAfterThird = debouncer.process(1)
        // Assert
        XCTAssertTrue(eventsAfterTwo.isEmpty)
        XCTAssertEqual(eventAfterThird, 1)
    }
}
