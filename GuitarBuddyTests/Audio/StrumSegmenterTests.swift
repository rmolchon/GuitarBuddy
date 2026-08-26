import XCTest
@testable import GuitarBuddy

final class StrumSegmenterTests: XCTestCase {
    private let cMajor: Set<PitchClass> = [.c, .e, .g]
    private let aMinor: Set<PitchClass> = [.a, .c, .e]

    func test_sustainedSameChordAcrossManyFramesEmitsExactlyOneEvent() {
        // Arrange
        let segmenter = StrumSegmenter()
        // Act
        let chords = chords(from: [cMajor, cMajor, cMajor, cMajor, cMajor].compactMap { segmenter.process(activePitchClasses: $0) })
        // Assert
        XCTAssertEqual(chords, [Chord(root: .c, quality: .major)])
    }

    func test_chordChangeHeldLongEnoughEmitsTwoEvents() {
        // Arrange
        let segmenter = StrumSegmenter()
        // Act
        let chords = chords(from: [cMajor, cMajor, aMinor, aMinor, aMinor].compactMap { segmenter.process(activePitchClasses: $0) })
        // Assert
        XCTAssertEqual(chords, [Chord(root: .c, quality: .major), Chord(root: .a, quality: .minor)])
    }

    func test_singleFrameBlipThatRevertsEmitsNoEvent() {
        // Arrange
        let segmenter = StrumSegmenter()
        // Act
        let chords = chords(from: [cMajor, cMajor, aMinor, cMajor, cMajor].compactMap { segmenter.process(activePitchClasses: $0) })
        // Assert
        XCTAssertEqual(chords, [Chord(root: .c, quality: .major)])
    }

    func test_silenceGapBetweenIdenticalChordsReArmsAndEmitsTwoEvents() {
        // Arrange
        let segmenter = StrumSegmenter()
        // Act
        let chords = chords(from: [cMajor, cMajor, [], [], cMajor, cMajor].compactMap { segmenter.process(activePitchClasses: $0) })
        // Assert
        XCTAssertEqual(chords, [Chord(root: .c, quality: .major), Chord(root: .c, quality: .major)])
    }

    func test_allSilenceEmitsNoEvents() {
        // Arrange
        let segmenter = StrumSegmenter()
        // Act
        let events = [Set<PitchClass>(), [], []].compactMap { segmenter.process(activePitchClasses: $0) }
        // Assert
        XCTAssertTrue(events.isEmpty)
    }

    func test_unrecognizableClusterIsTreatedLikeSilenceAndDoesNotEmit() {
        // Arrange
        let segmenter = StrumSegmenter()
        let noise: Set<PitchClass> = [.c, .cSharp, .d]
        // Act
        let events = [noise, noise, noise].compactMap { segmenter.process(activePitchClasses: $0) }
        // Assert
        XCTAssertTrue(events.isEmpty)
    }

    func test_fewerThanDebounceThresholdFramesOfNewChordEmitsNoEventYet() {
        // Arrange
        let segmenter = StrumSegmenter()
        // Act
        let events = [cMajor].compactMap { segmenter.process(activePitchClasses: $0) }
        // Assert
        XCTAssertTrue(events.isEmpty)
    }

    private func chords(from events: [TranscriptionEvent]) -> [Chord] {
        events.compactMap { event in
            if case .chord(let chord) = event { return chord }
            return nil
        }
    }
}
