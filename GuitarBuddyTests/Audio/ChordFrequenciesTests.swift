import XCTest
@testable import GuitarBuddy

final class ChordFrequenciesTests: XCTestCase {
    func test_majorTriadYieldsRootThirdAndFifthAtTheBaseOctave() {
        // Arrange
        let chord = Chord(root: .c, quality: .major)
        // Act
        let frequencies = ChordFrequencies.frequencies(for: chord, baseOctave: 3)
        // Assert
        let expected = [
            FrequencyToNote.frequency(forPitchClass: .c, octave: 3),
            FrequencyToNote.frequency(forPitchClass: .e, octave: 3),
            FrequencyToNote.frequency(forPitchClass: .g, octave: 3)
        ]
        XCTAssertEqual(frequencies.count, expected.count)
        for (actual, expectedValue) in zip(frequencies, expected) {
            XCTAssertEqual(actual, expectedValue, accuracy: 0.001)
        }
    }

    func test_frequencyCountMatchesTheQualitysIntervalCount() {
        // Arrange
        let chord = Chord(root: .g, quality: .dominant7)
        // Act
        let frequencies = ChordFrequencies.frequencies(for: chord, baseOctave: 3)
        // Assert
        XCTAssertEqual(frequencies.count, 4)
    }

    func test_toneFrequenciesAreEverIncreasingEvenWhenAnIntervalCrossesAnOctaveBoundary() {
        // A major7 interval (11 semitones) from a root near the top of the octave (B) pushes the
        // top chord tone into the next octave — this locks in that it rings higher, not wrapped
        // back down, which is what a naive `PitchClass.applying(semitones:)` mapping would do.
        let chord = Chord(root: .b, quality: .major7)

        let frequencies = ChordFrequencies.frequencies(for: chord, baseOctave: 3)

        for (previous, next) in zip(frequencies, frequencies.dropFirst()) {
            XCTAssertLessThan(previous, next)
        }
    }

    func test_higherBaseOctaveProducesProportionallyHigherFrequencies() {
        // Arrange
        let chord = Chord(root: .a, quality: .minor)
        // Act
        let lowerOctave = ChordFrequencies.frequencies(for: chord, baseOctave: 2)
        let higherOctave = ChordFrequencies.frequencies(for: chord, baseOctave: 3)
        // Assert
        for (low, high) in zip(lowerOctave, higherOctave) {
            XCTAssertEqual(high, low * 2, accuracy: 0.001)
        }
    }
}
