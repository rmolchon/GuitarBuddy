import XCTest
@testable import GuitarBuddy

final class PitchDetectorTests: XCTestCase {
    private let sampleRate: Double = 44100

    func test_detectsLowE2Frequency() {
        // Arrange
        let detector = PitchDetector()
        let samples = sineWave(frequency: 82.4, sampleRate: sampleRate, duration: 0.1)
        // Act
        let detected = detector.detectPitch(from: samples, sampleRate: sampleRate)
        // Assert
        XCTAssertNotNil(detected)
        XCTAssertEqual(detected!, 82.4, accuracy: 1.0)
    }

    func test_detectsA2Frequency() {
        let detector = PitchDetector()
        let samples = sineWave(frequency: 110.0, sampleRate: sampleRate, duration: 0.1)
        let detected = detector.detectPitch(from: samples, sampleRate: sampleRate)
        XCTAssertNotNil(detected)
        XCTAssertEqual(detected!, 110.0, accuracy: 1.0)
    }

    func test_detectsA4Frequency() {
        let detector = PitchDetector()
        let samples = sineWave(frequency: 440.0, sampleRate: sampleRate, duration: 0.1)
        let detected = detector.detectPitch(from: samples, sampleRate: sampleRate)
        XCTAssertNotNil(detected)
        XCTAssertEqual(detected!, 440.0, accuracy: 2.0)
    }

    func test_resistsOctaveErrorOnHarmonicRichWaveform() {
        let detector = PitchDetector()
        let samples = harmonicRichWave(fundamental: 110.0, sampleRate: sampleRate, duration: 0.1)
        let detected = detector.detectPitch(from: samples, sampleRate: sampleRate)
        XCTAssertNotNil(detected)
        XCTAssertEqual(detected!, 110.0, accuracy: 1.0)
    }

    func test_returnsNilForSilence() {
        let detector = PitchDetector()
        let samples = [Float](repeating: 0, count: 4410)
        XCTAssertNil(detector.detectPitch(from: samples, sampleRate: sampleRate))
    }

    func test_returnsNilForNoise() {
        let detector = PitchDetector()
        let samples = pseudoRandomNoise(count: 4410)
        XCTAssertNil(detector.detectPitch(from: samples, sampleRate: sampleRate))
    }

    func test_returnsNilForEmptyBuffer() {
        let detector = PitchDetector()
        XCTAssertNil(detector.detectPitch(from: [], sampleRate: sampleRate))
    }

    private func sineWave(frequency: Double, sampleRate: Double, duration: Double, amplitude: Double = 0.8) -> [Float] {
        let sampleCount = Int(sampleRate * duration)
        return (0..<sampleCount).map { i in
            Float(amplitude * sin(2 * Double.pi * frequency * Double(i) / sampleRate))
        }
    }

    private func harmonicRichWave(fundamental: Double, sampleRate: Double, duration: Double) -> [Float] {
        let sampleCount = Int(sampleRate * duration)
        return (0..<sampleCount).map { i in
            let t = Double(i) / sampleRate
            let weakFundamental = 0.3 * sin(2 * Double.pi * fundamental * t)
            let strongSecondHarmonic = 0.9 * sin(2 * Double.pi * fundamental * 2 * t)
            return Float(weakFundamental + strongSecondHarmonic)
        }
    }

    private func pseudoRandomNoise(count: Int, seed: UInt64 = 42) -> [Float] {
        var state = seed
        return (0..<count).map { _ in
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let normalized = Double(state >> 11) / Double(1 << 53)
            return Float(normalized * 2 - 1)
        }
    }
}
