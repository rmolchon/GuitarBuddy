import XCTest
@testable import GuitarBuddy

final class TranscribeViewModelTests: XCTestCase {
    func test_startSetsIsListeningAndAppendsChordsAsEventsArrive() async {
        // Arrange
        let fake = FakeAudioTranscriptionService()
        fake.eventsToYield = [
            .chord(Chord(root: .c, quality: .major)),
            .chord(Chord(root: .a, quality: .minor))
        ]
        let viewModel = TranscribeViewModel(transcriptionService: fake)
        // Act
        viewModel.start()
        // Assert
        XCTAssertTrue(viewModel.isListening)
        await waitUntil { viewModel.chords.count == 2 }
        XCTAssertEqual(viewModel.chords, [Chord(root: .c, quality: .major), Chord(root: .a, quality: .minor)])
    }

    func test_streamErrorSetsErrorMessageButLeavesIsListeningUntilExplicitStop() async {
        // Arrange
        let fake = FakeAudioTranscriptionService()
        fake.errorToThrow = TranscribeTestError.microphoneUnavailable
        let viewModel = TranscribeViewModel(transcriptionService: fake)
        // Act
        viewModel.start()
        // Assert
        await waitUntil { viewModel.errorMessage != nil }
        XCTAssertTrue(viewModel.isListening)

        viewModel.stop()
        XCTAssertFalse(viewModel.isListening)
    }

    func test_clearRemovesAllCollectedChords() async {
        // Arrange
        let fake = FakeAudioTranscriptionService()
        fake.eventsToYield = [.chord(Chord(root: .g, quality: .major))]
        let viewModel = TranscribeViewModel(transcriptionService: fake)
        viewModel.start()
        await waitUntil { viewModel.chords.count == 1 }
        // Act
        viewModel.clear()
        // Assert
        XCTAssertTrue(viewModel.chords.isEmpty)
    }

    func test_noteEventsInTheStreamAreIgnored() async {
        // Arrange: defensive — this service only ever yields .chord, but the shared
        // TranscriptionEvent type also has a .note case (used by Hum Mode).
        let fake = FakeAudioTranscriptionService()
        fake.eventsToYield = [
            .note(DetectedNote(pitchClass: .c, octave: 4, cents: 0)),
            .chord(Chord(root: .d, quality: .minor))
        ]
        let viewModel = TranscribeViewModel(transcriptionService: fake)
        // Act
        viewModel.start()
        // Assert
        await waitUntil { viewModel.chords.count == 1 }
        XCTAssertEqual(viewModel.chords, [Chord(root: .d, quality: .minor)])
    }

    private func waitUntil(_ condition: @escaping () -> Bool, timeout: TimeInterval = 1.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}

private enum TranscribeTestError: Error {
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
