import XCTest
@testable import GuitarBuddy

final class ChordRecognizerTests: XCTestCase {
    func test_recognizesMajorTriad() {
        // Arrange / Act
        let chord = ChordRecognizer.recognizeChord(from: [.c, .e, .g])
        // Assert
        XCTAssertEqual(chord, Chord(root: .c, quality: .major))
    }

    func test_recognizesMinorTriad() {
        let chord = ChordRecognizer.recognizeChord(from: [.a, .c, .e])
        XCTAssertEqual(chord, Chord(root: .a, quality: .minor))
    }

    func test_prefersLargerDominant7TemplateOverTheMajorTriadSubsetItAlsoSatisfies() {
        let chord = ChordRecognizer.recognizeChord(from: [.c, .e, .g, .aSharp])
        XCTAssertEqual(chord, Chord(root: .c, quality: .dominant7))
    }

    func test_recognizesMajor7() {
        let chord = ChordRecognizer.recognizeChord(from: [.c, .e, .g, .b])
        XCTAssertEqual(chord, Chord(root: .c, quality: .major7))
    }

    func test_recognizesMinor7() {
        let chord = ChordRecognizer.recognizeChord(from: [.a, .c, .e, .g])
        XCTAssertEqual(chord, Chord(root: .a, quality: .minor7))
    }

    func test_recognizesDiminished() {
        let chord = ChordRecognizer.recognizeChord(from: [.c, .dSharp, .fSharp])
        XCTAssertEqual(chord, Chord(root: .c, quality: .diminished))
    }

    func test_recognizesAugmented() {
        let chord = ChordRecognizer.recognizeChord(from: [.c, .e, .gSharp])
        XCTAssertEqual(chord, Chord(root: .c, quality: .augmented))
    }

    func test_recognizesSus2() {
        let chord = ChordRecognizer.recognizeChord(from: [.c, .d, .g])
        XCTAssertEqual(chord, Chord(root: .c, quality: .sus2))
    }

    func test_recognizesSus4() {
        let chord = ChordRecognizer.recognizeChord(from: [.c, .f, .g])
        XCTAssertEqual(chord, Chord(root: .c, quality: .sus4))
    }

    func test_toleratesExtraNotesBeyondTheChordTemplate() {
        // An extra harmonic/noise pitch class shouldn't block recognition of a full match.
        let chord = ChordRecognizer.recognizeChord(from: [.c, .e, .g, .fSharp])
        XCTAssertEqual(chord, Chord(root: .c, quality: .major))
    }

    func test_returnsNilForEmptySet() {
        XCTAssertNil(ChordRecognizer.recognizeChord(from: []))
    }

    func test_returnsNilForASingleNote() {
        XCTAssertNil(ChordRecognizer.recognizeChord(from: [.c]))
    }

    func test_returnsNilForANonChordCluster() {
        XCTAssertNil(ChordRecognizer.recognizeChord(from: [.c, .cSharp, .d]))
    }

    func test_symmetricAugmentedTriadResolvesToTheLowestRootInPitchClassOrder() {
        // {E, G#, C} is simultaneously E, G#, and C augmented (an augmented triad divides the
        // octave into equal thirds) — pitch-class sets alone can't tell which was actually played.
        // This locks in today's deterministic tie-break (lowest PitchClass.allCases root wins)
        // as an intentional, protected choice rather than an untested accident.
        let chord = ChordRecognizer.recognizeChord(from: [.e, .gSharp, .c])
        XCTAssertEqual(chord, Chord(root: .c, quality: .augmented))
    }

    func test_overlappingSus4AndSus2AFifthApartResolvesToTheLowestRootInPitchClassOrder() {
        // {A, D, E} is both A sus4 (0,5,7 from A) and D sus2 (0,2,7 from D) — same three pitch
        // classes. Locks in the same deterministic tie-break as the augmented-triad case above.
        let chord = ChordRecognizer.recognizeChord(from: [.a, .d, .e])
        XCTAssertEqual(chord, Chord(root: .d, quality: .sus2))
    }
}
