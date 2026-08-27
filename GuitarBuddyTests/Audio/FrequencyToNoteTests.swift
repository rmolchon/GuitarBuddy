import XCTest
@testable import GuitarBuddy

final class FrequencyToNoteTests: XCTestCase {
    func test_mapsA4ReferenceFrequencyToZeroCents() {
        // Arrange
        let frequency = 440.0
        // Act
        let note = FrequencyToNote.note(forFrequency: frequency)
        // Assert
        XCTAssertEqual(note?.pitchClass, .a)
        XCTAssertEqual(note?.octave, 4)
        XCTAssertEqual(note?.cents ?? .nan, 0, accuracy: 0.01)
    }

    func test_mapsLowE2Frequency() {
        let note = FrequencyToNote.note(forFrequency: 82.4)
        XCTAssertEqual(note?.pitchClass, .e)
        XCTAssertEqual(note?.octave, 2)
        XCTAssertEqual(note?.cents ?? .nan, 0, accuracy: 0.5)
    }

    func test_mapsHighE4Frequency() {
        let note = FrequencyToNote.note(forFrequency: 329.63)
        XCTAssertEqual(note?.pitchClass, .e)
        XCTAssertEqual(note?.octave, 4)
        XCTAssertEqual(note?.cents ?? .nan, 0, accuracy: 0.5)
    }

    func test_flipsDownToNearestSemitoneJustBelowBoundary() {
        let note = FrequencyToNote.note(forFrequency: 452.8)
        XCTAssertEqual(note?.pitchClass, .a)
        XCTAssertEqual(note?.octave, 4)
        XCTAssertEqual(note?.cents ?? .nan, 49.6, accuracy: 0.5)
    }

    func test_flipsUpToNextSemitoneJustAboveBoundary() {
        let note = FrequencyToNote.note(forFrequency: 453.0)
        XCTAssertEqual(note?.pitchClass, .aSharp)
        XCTAssertEqual(note?.octave, 4)
        XCTAssertEqual(note?.cents ?? .nan, -49.6, accuracy: 0.5)
    }

    func test_respectsNonDefaultReferencePitch() {
        let note = FrequencyToNote.note(forFrequency: 432.0, referencePitch: 432.0)
        XCTAssertEqual(note?.pitchClass, .a)
        XCTAssertEqual(note?.octave, 4)
        XCTAssertEqual(note?.cents ?? .nan, 0, accuracy: 0.01)
    }

    func test_returnsNilForZeroFrequency() {
        XCTAssertNil(FrequencyToNote.note(forFrequency: 0))
    }

    func test_returnsNilForNegativeFrequency() {
        XCTAssertNil(FrequencyToNote.note(forFrequency: -10))
    }

    func test_frequencyForPitchClassReturnsA4ReferenceFrequency() {
        let frequency = FrequencyToNote.frequency(forPitchClass: .a, octave: 4)
        XCTAssertEqual(frequency, 440.0, accuracy: 0.001)
    }

    func test_frequencyForPitchClassMatchesKnownLowE2Frequency() {
        let frequency = FrequencyToNote.frequency(forPitchClass: .e, octave: 2)
        XCTAssertEqual(frequency, 82.4, accuracy: 0.1)
    }

    func test_frequencyForPitchClassRespectsNonDefaultReferencePitch() {
        let frequency = FrequencyToNote.frequency(forPitchClass: .a, octave: 4, referencePitch: 432.0)
        XCTAssertEqual(frequency, 432.0, accuracy: 0.001)
    }

    func test_frequencyForPitchClassRoundTripsThroughNoteForFrequency() {
        let frequency = FrequencyToNote.frequency(forPitchClass: .fSharp, octave: 3)
        let note = FrequencyToNote.note(forFrequency: frequency)
        XCTAssertEqual(note?.pitchClass, .fSharp)
        XCTAssertEqual(note?.octave, 3)
        XCTAssertEqual(note?.cents ?? .nan, 0, accuracy: 0.01)
    }

    func test_neighborNoteOneSemitoneUpWithinSameOctave() {
        let neighbor = FrequencyToNote.neighborNote(pitchClass: .a, octave: 2, semitones: 1)
        XCTAssertEqual(neighbor.pitchClass, .aSharp)
        XCTAssertEqual(neighbor.octave, 2)
    }

    func test_neighborNoteOneSemitoneDownWithinSameOctave() {
        let neighbor = FrequencyToNote.neighborNote(pitchClass: .a, octave: 2, semitones: -1)
        XCTAssertEqual(neighbor.pitchClass, .gSharp)
        XCTAssertEqual(neighbor.octave, 2)
    }

    func test_neighborNoteWrapsOctaveUpAtB() {
        let neighbor = FrequencyToNote.neighborNote(pitchClass: .b, octave: 4, semitones: 1)
        XCTAssertEqual(neighbor.pitchClass, .c)
        XCTAssertEqual(neighbor.octave, 5)
    }

    func test_neighborNoteWrapsOctaveDownAtC() {
        let neighbor = FrequencyToNote.neighborNote(pitchClass: .c, octave: 4, semitones: -1)
        XCTAssertEqual(neighbor.pitchClass, .b)
        XCTAssertEqual(neighbor.octave, 3)
    }
}
