import Foundation

final class HumTranscriptionService: AudioTranscriptionService {
    private let makeAudioEngineController: () -> AudioEngineController
    private let referencePitch: Double

    init(
        makeAudioEngineController: @escaping () -> AudioEngineController = { AudioEngineController() },
        referencePitch: Double = 440.0
    ) {
        self.makeAudioEngineController = makeAudioEngineController
        self.referencePitch = referencePitch
    }

    func transcribe(audioSource: AudioSource) -> AsyncThrowingStream<TranscriptionEvent, Error> {
        let audioEngineController = makeAudioEngineController()

        return AsyncThrowingStream { continuation in
            let streamTask = Task {
                do {
                    try await audioEngineController.start()
                } catch {
                    AppLogger.humMode.error("Failed to start audio engine: \(error.localizedDescription, privacy: .public)")
                    audioEngineController.stop()
                    continuation.finish(throwing: error)
                    return
                }

                let segmenter = HumNoteSegmenter(referencePitch: referencePitch)
                let pitchStream = audioEngineController.pitchStream
                for await frequency in pitchStream {
                    if let event = segmenter.process(frequency: frequency) {
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
