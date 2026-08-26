import XCTest
@testable import GuitarBuddy

final class HumNoteSegmenterTests: XCTestCase {
    private let a4: Double = 440.0
    private let b4: Double = 440.0 * pow(2, 2.0 / 12.0)

    func test_sustainedSameNoteAcrossManyFramesEmitsExactlyOneEvent() {
        // Arrange
        let segmenter = HumNoteSegmenter()
        // Act
        let notes = notes(from: [a4, a4, a4, a4, a4].compactMap { segmenter.process(frequency: $0) })
        // Assert
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.pitchClass, .a)
        XCTAssertEqual(notes.first?.octave, 4)
    }

    func test_noteChangeHeldLongEnoughEmitsTwoEvents() {
        // Arrange
        let segmenter = HumNoteSegmenter()
        // Act
        let notes = notes(from: [a4, a4, b4, b4, b4].compactMap { segmenter.process(frequency: $0) })
        // Assert
        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes[0].pitchClass, .a)
        XCTAssertEqual(notes[1].pitchClass, .b)
    }

    func test_singleFrameBlipThatRevertsEmitsNoEvent() {
        // Arrange
        let segmenter = HumNoteSegmenter()
        // Act
        let notes = notes(from: [a4, a4, b4, a4, a4].compactMap { segmenter.process(frequency: $0) })
        // Assert
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.pitchClass, .a)
    }

    func test_silenceGapBetweenIdenticalNotesReArmsAndEmitsTwoEvents() {
        // Arrange
        let segmenter = HumNoteSegmenter()
        // Act
        let notes = notes(from: [a4, a4, nil, nil, a4, a4].compactMap { segmenter.process(frequency: $0) })
        // Assert
        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes[0].pitchClass, .a)
        XCTAssertEqual(notes[1].pitchClass, .a)
    }

    func test_allNilStreamEmitsNoEvents() {
        // Arrange
        let segmenter = HumNoteSegmenter()
        // Act
        let events: [TranscriptionEvent] = [nil, nil, nil].compactMap { (frequency: Double?) in
            segmenter.process(frequency: frequency)
        }
        // Assert
        XCTAssertTrue(events.isEmpty)
    }

    func test_fewerThanDebounceThresholdFramesOfNewNoteEmitsNoEventYet() {
        // Arrange
        let segmenter = HumNoteSegmenter()
        // Act
        let events = [a4].compactMap { segmenter.process(frequency: $0) }
        // Assert
        XCTAssertTrue(events.isEmpty)
    }

    private func notes(from events: [TranscriptionEvent]) -> [DetectedNote] {
        events.compactMap { event in
            if case .note(let note) = event { return note }
            return nil
        }
    }
}
