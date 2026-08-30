import XCTest
@testable import GuitarBuddy

final class ChordAudioSynthesizerTests: XCTestCase {
    func test_returnsEmptySamplesForAnEmptyChordSequence() {
        // Arrange / Act
        let samples = ChordAudioSynthesizer.samples(for: [])
        // Assert
        XCTAssertTrue(samples.isEmpty)
    }

    func test_singleChordProducesExactlyOneChordDurationsWorthOfSamples() {
        // Arrange
        let chord = Chord(root: .c, quality: .major)
        let expectedFrameCount = Int(ChordAudioSynthesizer.chordDuration * ChordAudioSynthesizer.sampleRate)
        // Act
        let samples = ChordAudioSynthesizer.samples(for: [chord])
        // Assert
        XCTAssertEqual(samples.count, expectedFrameCount)
    }

    func test_multipleChordsAreSeparatedByASilentGap() {
        // Arrange
        let chords = [Chord(root: .c, quality: .major), Chord(root: .g, quality: .major)]
        let chordFrames = Int(ChordAudioSynthesizer.chordDuration * ChordAudioSynthesizer.sampleRate)
        let gapFrames = Int(ChordAudioSynthesizer.gapDuration * ChordAudioSynthesizer.sampleRate)
        // Act
        let samples = ChordAudioSynthesizer.samples(for: chords)
        // Assert
        XCTAssertEqual(samples.count, chordFrames * 2 + gapFrames)
    }

    func test_fadesInFromSilenceAtTheStartOfEachChordToAvoidAClick() {
        // Arrange
        let chord = Chord(root: .c, quality: .major)
        // Act
        let samples = ChordAudioSynthesizer.samples(for: [chord])
        // Assert
        XCTAssertEqual(samples.first ?? -1, 0, accuracy: 0.0001)
    }

    func test_neverClipsBeyondTheConfiguredAmplitude() {
        // Arrange: a dense 4-note chord is the worst case for constructive interference.
        let chord = Chord(root: .c, quality: .dominant7)
        // Act
        let samples = ChordAudioSynthesizer.samples(for: [chord])
        // Assert
        XCTAssertTrue(samples.allSatisfy { abs($0) <= 0.2001 })
    }
}
