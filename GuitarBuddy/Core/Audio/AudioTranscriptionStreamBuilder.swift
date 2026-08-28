import Foundation
import os

/// Shared start/stream/cleanup lifecycle for `AudioTranscriptionService` conformers.
/// `HumTranscriptionService` and `StrumTranscriptionService` differ only in which
/// `AudioEngineController` stream they read from and how a raw value becomes a
/// `TranscriptionEvent` — this factors out the surrounding engine start, error propagation,
/// and cancellation/cleanup they'd otherwise duplicate.
enum AudioTranscriptionStreamBuilder {
    static func makeStream<Raw>(
        audioEngineController: AudioEngineController,
        rawStream: @escaping (AudioEngineController) -> AsyncStream<Raw>,
        logger: Logger,
        process: @escaping (Raw) -> TranscriptionEvent?
    ) -> AsyncThrowingStream<TranscriptionEvent, Error> {
        AsyncThrowingStream { continuation in
            let streamTask = Task {
                do {
                    try await audioEngineController.start()
                } catch {
                    logger.error("Failed to start audio engine: \(error.localizedDescription, privacy: .public)")
                    audioEngineController.stop()
                    continuation.finish(throwing: error)
                    return
                }

                for await raw in rawStream(audioEngineController) {
                    if let event = process(raw) {
                        continuation.yield(event)
                    }
                }
                continuation.finish()
            }

            continuation.onTermination = { [audioEngineController] _ in
                streamTask.cancel()
                audioEngineController.stop()
            }
        }
    }
}
