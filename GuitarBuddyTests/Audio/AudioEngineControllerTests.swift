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

    func test_frameFromBufferCapturesSamplesAndSampleRate() {
        let buffer = makeBuffer(samples: [0.1, -0.2, 0.3], sampleRate: 48000)

        let frame = AudioEngineController.frame(from: buffer)

        XCTAssertEqual(frame?.samples, [0.1, -0.2, 0.3])
        XCTAssertEqual(frame?.sampleRate, 48000)
    }

    func test_frameFromEmptyBufferReturnsNil() {
        let buffer = makeBuffer(samples: [], sampleRate: 44100)
        XCTAssertNil(AudioEngineController.frame(from: buffer))
    }

    func test_handlePassesSamplesAndSampleRateToInjectedDetector() async {
        let spy = SpyPitchDetector(stubbedPitch: 123.0)
        let controller = AudioEngineController(pitchDetector: spy)
        let frame = AudioFrame(samples: [0.1, 0.2, 0.3], sampleRate: 48000)

        controller.handle(frame)
        var pitchIterator = controller.pitchStream.makeAsyncIterator()
        let pitch = (await pitchIterator.next()).flatMap { $0 }

        XCTAssertEqual(spy.receivedSamples, [0.1, 0.2, 0.3])
        XCTAssertEqual(spy.receivedSampleRate, 48000)
        XCTAssertEqual(pitch, 123.0)
    }

    func test_handleYieldsDetectedPitchForSyntheticSineFrame() async {
        let controller = AudioEngineController(pitchDetector: PitchDetector())
        let frame = AudioFrame(samples: sineWave(frequency: 440.0, sampleRate: 44100, duration: 0.1), sampleRate: 44100)

        controller.handle(frame)
        var pitchIterator = controller.pitchStream.makeAsyncIterator()
        let pitch = (await pitchIterator.next()).flatMap { $0 }

        XCTAssertNotNil(pitch)
        XCTAssertEqual(pitch ?? 0, 440.0, accuracy: 2.0)
    }

    func test_handleYieldsNilPitchForSilence() async {
        let controller = AudioEngineController(pitchDetector: PitchDetector())
        let frame = AudioFrame(samples: [Float](repeating: 0, count: 4410), sampleRate: 44100)

        controller.handle(frame)
        var pitchIterator = controller.pitchStream.makeAsyncIterator()
        let pitch = (await pitchIterator.next()).flatMap { $0 }

        XCTAssertNil(pitch)
    }

    func test_handleAlsoYieldsFrameOnFrameStreamRegardlessOfPitchDetection() async {
        let controller = AudioEngineController(pitchDetector: PitchDetector())
        let frame = AudioFrame(samples: [Float](repeating: 0, count: 10), sampleRate: 44100)

        controller.handle(frame)
        var frameIterator = controller.frameStream.makeAsyncIterator()
        let received = await frameIterator.next()

        XCTAssertEqual(received?.samples.count, 10)
    }

    func test_startThrowsPermissionDeniedWhenPermissionIsDenied() async {
        let controller = AudioEngineController(
            pitchDetector: PitchDetector(),
            permissionProvider: FakeRecordPermissionProvider(recordPermission: .denied)
        )

        do {
            try await controller.start()
            XCTFail("expected start() to throw")
        } catch {
            XCTAssertEqual(error as? AudioEngineControllerError, .permissionDenied)
        }
    }

    func test_startThrowsPermissionDeniedWhenUndeterminedRequestIsDeclined() async {
        let controller = AudioEngineController(
            pitchDetector: PitchDetector(),
            permissionProvider: FakeRecordPermissionProvider(recordPermission: .undetermined, requestRecordPermissionResult: false)
        )

        do {
            try await controller.start()
            XCTFail("expected start() to throw")
        } catch {
            XCTAssertEqual(error as? AudioEngineControllerError, .permissionDenied)
        }
    }

    func test_startFailureSetsTerminationErrorAndFinishesStreams() async {
        // Permission stubbed granted, but the XCTest host has no valid audio input route,
        // so start() reliably throws invalidInputFormat and must fully unwind.
        let controller = AudioEngineController(
            pitchDetector: PitchDetector(),
            permissionProvider: FakeRecordPermissionProvider()
        )

        do {
            try await controller.start()
            XCTFail("expected start() to throw in the test host")
        } catch {
            XCTAssertEqual(error as? AudioEngineControllerError, .invalidInputFormat)
        }

        XCTAssertEqual(controller.terminationError, .invalidInputFormat)
        await assertStreamsFinished(controller)
    }

    func test_stopWithoutStartIsSafeAndFinishesStreams() async {
        let controller = AudioEngineController(pitchDetector: PitchDetector())

        controller.stop()

        XCTAssertNil(controller.terminationError)
        await assertStreamsFinished(controller)
    }

    func test_stopIsIdempotent() async {
        let controller = AudioEngineController(pitchDetector: PitchDetector())

        controller.stop()
        controller.stop()

        await assertStreamsFinished(controller)
    }

    func test_interruptionNotificationFinishesStreamsAndSetsInterruptedError() async {
        let controller = AudioEngineController(pitchDetector: PitchDetector())

        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )

        // Let the notification observer run.
        await Task.yield()

        XCTAssertEqual(controller.terminationError, .interrupted)
        await assertStreamsFinished(controller)
    }

    // MARK: - Helpers

    private func assertStreamsFinished(
        _ controller: AudioEngineController,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        var pitchIterator = controller.pitchStream.makeAsyncIterator()
        let pitch = await pitchIterator.next()
        XCTAssertNil(pitch as Any?, "pitchStream should be finished", file: file, line: line)

        var frameIterator = controller.frameStream.makeAsyncIterator()
        let frame = await frameIterator.next()
        XCTAssertNil(frame, "frameStream should be finished", file: file, line: line)
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
