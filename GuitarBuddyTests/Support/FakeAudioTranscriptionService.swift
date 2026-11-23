@testable import GuitarBuddy

/// Replays a canned list of events (then finishes, or throws `errorToThrow`) so view-model tests
/// don't need AVFoundation.
final class FakeAudioTranscriptionService: AudioTranscriptionService, @unchecked Sendable {
    private let events = LockedBox<[TranscriptionEvent]>([])
    private let error = LockedBox<Error?>(nil)

    var eventsToYield: [TranscriptionEvent] {
        get { events.value }
        set { events.value = newValue }
    }

    var errorToThrow: Error? {
        get { error.value }
        set { error.value = newValue }
    }

    func transcribe(audioSource: AudioSource) -> AsyncThrowingStream<TranscriptionEvent, Error> {
        let eventsToYield = eventsToYield
        let errorToThrow = errorToThrow
        return AsyncThrowingStream { continuation in
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
