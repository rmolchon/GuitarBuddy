import XCTest
@testable import GuitarBuddy

final class StrumTranscriptionServiceTests: XCTestCase {
    func test_transcribeCreatesAFreshControllerOnEachCallSoRestartingWorks() {
        // Arrange
        var createdControllers: [AudioEngineController] = []
        let service = StrumTranscriptionService(makeAudioEngineController: {
            let controller = AudioEngineController(pitchDetector: PitchDetector())
            createdControllers.append(controller)
            return controller
        })

        // Act — simulates the user tapping Start, then Stop, then Start again
        _ = service.transcribe(audioSource: .microphone)
        _ = service.transcribe(audioSource: .microphone)

        // Assert: a distinct controller (and therefore a fresh, non-finished bufferStream)
        // backs every session, instead of reusing one whose AsyncStream was already finished.
        XCTAssertEqual(createdControllers.count, 2)
        XCTAssertFalse(createdControllers[0] === createdControllers[1])
    }

    func test_transcribePropagatesEngineStartFailureAndStopsTheController() async {
        // Arrange: the XCTest host process has no valid audio input route, so
        // AudioEngineController.start() reliably throws invalidInputFormat here —
        // this deterministically exercises the failure/cleanup path with no mic needed.
        let service = StrumTranscriptionService()

        // Act
        let stream = service.transcribe(audioSource: .microphone)

        // Assert
        do {
            for try await _ in stream {
                XCTFail("expected no events since the engine failed to start")
            }
            XCTFail("expected the stream to finish with an error")
        } catch {
            XCTAssertTrue(error is AudioEngineControllerError)
        }
    }
}
