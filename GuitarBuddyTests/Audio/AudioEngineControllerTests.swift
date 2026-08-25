import XCTest
import AVFoundation
@testable import GuitarBuddy

final class AudioEngineControllerTests: XCTestCase {
    func test_samplesFromBufferExtractsFloatChannelData() {
        // Arrange
        let buffer = makeBuffer(samples: [0.1, -0.2, 0.3], sampleRate: 44100)
        // Act
        let samples = AudioEngineController.samples(from: buffer)
        // Assert
        XCTAssertEqual(samples, [0.1, -0.2, 0.3])
    }

    func test_samplesFromEmptyBufferReturnsNil() {
        let buffer = makeBuffer(samples: [], sampleRate: 44100)
        XCTAssertNil(AudioEngineController.samples(from: buffer))
    }

    func test_handlePassesSamplesAndSampleRateToInjectedDetector() async {
        let spy = SpyPitchDetector(stubbedPitch: 123.0)
        let controller = AudioEngineController(pitchDetector: spy)
        let buffer = makeBuffer(samples: [0.1, 0.2, 0.3], sampleRate: 48000)

        controller.handle(buffer)
        var pitchIterator = controller.pitchStream.makeAsyncIterator()
        let pitch = (await pitchIterator.next()).flatMap { $0 }

        XCTAssertEqual(spy.receivedSamples, [0.1, 0.2, 0.3])
        XCTAssertEqual(spy.receivedSampleRate, 48000)
        XCTAssertEqual(pitch, 123.0)
    }

    func test_handleYieldsDetectedPitchForSyntheticSineBuffer() async {
        let controller = AudioEngineController(pitchDetector: PitchDetector())
        let buffer = makeBuffer(samples: sineWave(frequency: 440.0, sampleRate: 44100, duration: 0.1), sampleRate: 44100)

        controller.handle(buffer)
        var pitchIterator = controller.pitchStream.makeAsyncIterator()
        let pitch = (await pitchIterator.next()).flatMap { $0 }

        XCTAssertNotNil(pitch)
        XCTAssertEqual(pitch ?? 0, 440.0, accuracy: 2.0)
    }

    func test_handleYieldsNilPitchForSilence() async {
        let controller = AudioEngineController(pitchDetector: PitchDetector())
        let buffer = makeBuffer(samples: [Float](repeating: 0, count: 4410), sampleRate: 44100)

        controller.handle(buffer)
        var pitchIterator = controller.pitchStream.makeAsyncIterator()
        let pitch = (await pitchIterator.next()).flatMap { $0 }

        XCTAssertNil(pitch)
    }

    func test_handleAlsoYieldsRawBufferOnBufferStreamRegardlessOfPitchDetection() async {
        let controller = AudioEngineController(pitchDetector: PitchDetector())
        let buffer = makeBuffer(samples: [Float](repeating: 0, count: 10), sampleRate: 44100)

        controller.handle(buffer)
        var bufferIterator = controller.bufferStream.makeAsyncIterator()
        let received = await bufferIterator.next()

        XCTAssertEqual(received?.frameLength, buffer.frameLength)
    }

    private func makeBuffer(samples: [Float], sampleRate: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(max(samples.count, 1)))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let channelData = buffer.floatChannelData {
            for (index, sample) in samples.enumerated() {
                channelData[0][index] = sample
            }
        }
        return buffer
    }

    private func sineWave(frequency: Double, sampleRate: Double, duration: Double, amplitude: Double = 0.8) -> [Float] {
        let sampleCount = Int(sampleRate * duration)
        return (0..<sampleCount).map { i in
            Float(amplitude * sin(2 * Double.pi * frequency * Double(i) / sampleRate))
        }
    }
}

private final class SpyPitchDetector: PitchDetecting {
    private(set) var receivedSamples: [Float]?
    private(set) var receivedSampleRate: Double?
    private let stubbedPitch: Double?

    init(stubbedPitch: Double?) {
        self.stubbedPitch = stubbedPitch
    }

    func detectPitch(from samples: [Float], sampleRate: Double) -> Double? {
        receivedSamples = samples
        receivedSampleRate = sampleRate
        return stubbedPitch
    }
}
