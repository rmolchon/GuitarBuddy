import XCTest
@testable import GuitarBuddy

final class ChordTests: XCTestCase {
    func test_parsesSimpleMajorChord() {
        // Arrange
        let symbol = "C"
        // Act
        let chord = Chord.parse(symbol)
        // Assert
        XCTAssertEqual(chord, Chord(root: .c, quality: .major))
    }

    func test_parsesSharpRoot() {
        let chord = Chord.parse("C#")
        XCTAssertEqual(chord, Chord(root: .cSharp, quality: .major))
    }

    func test_parsesFlatRoot() {
        let chord = Chord.parse("Bb")
        XCTAssertEqual(chord, Chord(root: .aSharp, quality: .major))
    }

    func test_parsesMinorChord() {
        let chord = Chord.parse("Dm")
        XCTAssertEqual(chord, Chord(root: .d, quality: .minor))
    }

    func test_parsesFlatMinorChord() {
        let chord = Chord.parse("Bbm")
        XCTAssertEqual(chord, Chord(root: .aSharp, quality: .minor))
    }

    func test_parsesDominantSeventh() {
        let chord = Chord.parse("G7")
        XCTAssertEqual(chord, Chord(root: .g, quality: .dominant7))
    }

    func test_parsesMinorSeventh() {
        let chord = Chord.parse("Am7")
        XCTAssertEqual(chord, Chord(root: .a, quality: .minor7))
    }

    func test_parsesMajorSeventh() {
        let chord = Chord.parse("Fmaj7")
        XCTAssertEqual(chord, Chord(root: .f, quality: .major7))
    }

    func test_parsesDiminished() {
        let chord = Chord.parse("Bdim")
        XCTAssertEqual(chord, Chord(root: .b, quality: .diminished))
    }

    func test_parsesAugmented() {
        let chord = Chord.parse("Caug")
        XCTAssertEqual(chord, Chord(root: .c, quality: .augmented))
    }

    func test_parsesSus2() {
        let chord = Chord.parse("Dsus2")
        XCTAssertEqual(chord, Chord(root: .d, quality: .sus2))
    }

    func test_parsesSus4() {
        let chord = Chord.parse("Dsus4")
        XCTAssertEqual(chord, Chord(root: .d, quality: .sus4))
    }

    func test_parsesUnicodeSharp() {
        let chord = Chord.parse("C\u{266F}")
        XCTAssertEqual(chord, Chord(root: .cSharp, quality: .major))
    }

    func test_isCaseInsensitiveForRootLetter() {
        let chord = Chord.parse("c")
        XCTAssertEqual(chord, Chord(root: .c, quality: .major))
    }

    func test_returnsNilForEmptyString() {
        XCTAssertNil(Chord.parse(""))
    }

    func test_returnsNilForInvalidRootLetter() {
        XCTAssertNil(Chord.parse("H"))
    }

    func test_returnsNilForGarbageSuffix() {
        XCTAssertNil(Chord.parse("Cxyz123"))
    }
}
