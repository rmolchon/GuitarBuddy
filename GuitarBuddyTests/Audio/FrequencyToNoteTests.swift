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
}
