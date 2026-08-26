import XCTest
@testable import GuitarBuddy

final class ChromaExtractorTests: XCTestCase {
    private let sampleRate: Double = 44100
    private let duration: Double = 0.2

    func test_detectsActivePitchClassesForACMajorChordSineMixture() {
        // Arrange
        let samples = mix([
            sineWave(frequency: FrequencyToNote.frequency(forPitchClass: .c, octave: 4)),
            sineWave(frequency: FrequencyToNote.frequency(forPitchClass: .e, octave: 4)),
            sineWave(frequency: FrequencyToNote.frequency(forPitchClass: .g, octave: 4))
        ])
        // Act
        let activePitchClasses = ChromaExtractor.activePitchClasses(from: samples, sampleRate: sampleRate)
        // Assert
        XCTAssertEqual(activePitchClasses, [.c, .e, .g])
    }

    func test_detectsActivePitchClassesForAnAMinorChordSineMixture() {
        // Arrange
        let samples = mix([
            sineWave(frequency: FrequencyToNote.frequency(forPitchClass: .a, octave: 3)),
            sineWave(frequency: FrequencyToNote.frequency(forPitchClass: .c, octave: 4)),
            sineWave(frequency: FrequencyToNote.frequency(forPitchClass: .e, octave: 4))
        ])
        // Act
        let activePitchClasses = ChromaExtractor.activePitchClasses(from: samples, sampleRate: sampleRate)
        // Assert
        XCTAssertEqual(activePitchClasses, [.a, .c, .e])
    }

    func test_singleToneOnlyActivatesItsOwnPitchClass() {
        // Arrange
        let samples = sineWave(frequency: FrequencyToNote.frequency(forPitchClass: .a, octave: 4))
        // Act
        let activePitchClasses = ChromaExtractor.activePitchClasses(from: samples, sampleRate: sampleRate)
        // Assert
        XCTAssertEqual(activePitchClasses, [.a])
    }

    func test_returnsEmptySetForSilence() {
        // Arrange
        let samples = [Float](repeating: 0, count: Int(sampleRate * duration))
        // Act
        let activePitchClasses = ChromaExtractor.activePitchClasses(from: samples, sampleRate: sampleRate)
        // Assert
        XCTAssertTrue(activePitchClasses.isEmpty)
    }

    private func sineWave(frequency: Double, amplitude: Double = 0.25) -> [Float] {
        let sampleCount = Int(sampleRate * duration)
        return (0..<sampleCount).map { i in
            Float(amplitude * sin(2 * Double.pi * frequency * Double(i) / sampleRate))
        }
    }

    private func mix(_ waves: [[Float]]) -> [Float] {
        let count = waves.map(\.count).min() ?? 0
        return (0..<count).map { index in waves.reduce(0) { $0 + $1[index] } }
    }
}
