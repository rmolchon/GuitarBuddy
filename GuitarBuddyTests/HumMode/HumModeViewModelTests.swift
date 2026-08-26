import XCTest
@testable import GuitarBuddy

final class HumModeViewModelTests: XCTestCase {
    func test_startSetsIsListeningAndAppendsNotesAsEventsArrive() async {
        // Arrange
        let fake = FakeAudioTranscriptionService()
        fake.eventsToYield = [
            TranscriptionEvent(note: DetectedNote(pitchClass: .c, octave: 4, cents: 0)),
            TranscriptionEvent(note: DetectedNote(pitchClass: .e, octave: 4, cents: 0))
        ]
        let viewModel = HumModeViewModel(transcriptionService: fake)
        // Act
        viewModel.start()
        // Assert
        XCTAssertTrue(viewModel.isListening)
        await waitUntil { viewModel.notes.count == 2 }
        XCTAssertEqual(viewModel.notes.map(\.pitchClass), [.c, .e])
    }

    func test_streamErrorSetsErrorMessageButLeavesIsListeningUntilExplicitStop() async {
        // Arrange
        let fake = FakeAudioTranscriptionService()
        fake.errorToThrow = HumTranscriptionTestError.microphoneUnavailable
        let viewModel = HumModeViewModel(transcriptionService: fake)
        // Act
        viewModel.start()
        // Assert
        await waitUntil { viewModel.errorMessage != nil }
        XCTAssertTrue(viewModel.isListening)

        viewModel.stop()
        XCTAssertFalse(viewModel.isListening)
    }

    func test_clearRemovesAllCollectedNotes() async {
        // Arrange
        let fake = FakeAudioTranscriptionService()
        fake.eventsToYield = [TranscriptionEvent(note: DetectedNote(pitchClass: .a, octave: 4, cents: 0))]
        let viewModel = HumModeViewModel(transcriptionService: fake)
        viewModel.start()
        await waitUntil { viewModel.notes.count == 1 }
        // Act
        viewModel.clear()
        // Assert
        XCTAssertTrue(viewModel.notes.isEmpty)
    }

    private func waitUntil(_ condition: @escaping () -> Bool, timeout: TimeInterval = 1.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}

private enum HumTranscriptionTestError: Error {
    case microphoneUnavailable
}

private final class FakeAudioTranscriptionService: AudioTranscriptionService {
    var eventsToYield: [TranscriptionEvent] = []
    var errorToThrow: Error?

    func transcribe(audioSource: AudioSource) -> AsyncThrowingStream<TranscriptionEvent, Error> {
        AsyncThrowingStream { continuation in
            for event in eventsToYield {
                continuation.yield(event)
            }
            if let errorToThrow {
                continuation.finish(throwing: errorToThrow)
            } else {
                continuation.finish()
            }
        }
    }
}
