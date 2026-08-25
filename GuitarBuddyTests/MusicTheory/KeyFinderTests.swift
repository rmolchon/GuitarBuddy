import XCTest
@testable import GuitarBuddy

final class KeyFinderTests: XCTestCase {
    func test_identifiesKeyFromCommonProgression() {
        // Arrange
        let chords = [Chord.parse("C")!, Chord.parse("Am")!, Chord.parse("F")!, Chord.parse("G")!]
        // Act
        let result = KeyFinder.findKey(for: chords)
        // Assert
        XCTAssertEqual(result.key, MusicalKey(tonic: .c))
        XCTAssertEqual(result.confidence, 1.0, accuracy: 0.0001)
        XCTAssertFalse(result.isAmbiguous)
    }

    func test_resolvesTiedKeysUsingDominantChordPresence() {
        let chords = [Chord.parse("C")!, Chord.parse("G")!]
        let result = KeyFinder.findKey(for: chords)
        XCTAssertEqual(result.key, MusicalKey(tonic: .c))
        XCTAssertEqual(result.confidence, 1.0, accuracy: 0.0001)
        XCTAssertFalse(result.isAmbiguous)
    }

    func test_resolvesSingleMinorChordToItsRelativeMajorKey() {
        let chords = [Chord.parse("Dm")!]
        let result = KeyFinder.findKey(for: chords)
        XCTAssertEqual(result.key, MusicalKey(tonic: .f))
        XCTAssertEqual(result.confidence, 1.0, accuracy: 0.0001)
        XCTAssertFalse(result.isAmbiguous)
    }

    func test_reportsAmbiguousWhenTiedKeysSurviveBothTieBreakStages() {
        let chords = [Chord.parse("C")!, Chord.parse("Em")!]
        let result = KeyFinder.findKey(for: chords)
        XCTAssertNil(result.key)
        XCTAssertEqual(result.confidence, 1.0, accuracy: 0.0001)
        XCTAssertTrue(result.isAmbiguous)
    }

    func test_toleratesABorrowedChordAndStillPicksTheDominantKey() {
        let chords = [Chord.parse("C")!, Chord.parse("F")!, Chord.parse("G")!, Chord.parse("Ab")!]
        let result = KeyFinder.findKey(for: chords)
        XCTAssertEqual(result.key, MusicalKey(tonic: .c))
        XCTAssertEqual(result.confidence, 0.75, accuracy: 0.0001)
        XCTAssertFalse(result.isAmbiguous)
    }

    func test_returnsAmbiguousResultForEmptyChordList() {
        let result = KeyFinder.findKey(for: [])
        XCTAssertNil(result.key)
        XCTAssertEqual(result.confidence, 0, accuracy: 0.0001)
        XCTAssertTrue(result.isAmbiguous)
    }
}
