import Foundation

final class StrumTranscriptionService: AudioTranscriptionService {
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
            do {
                try audioEngineController.start()
            } catch {
                audioEngineController.stop()
                continuation.finish(throwing: error)
                return
            }

            let segmenter = StrumSegmenter()
            let bufferStream = audioEngineController.bufferStream
            let referencePitch = referencePitch
            let consumerTask = Task {
                for await buffer in bufferStream {
                    guard let samples = AudioEngineController.samples(from: buffer) else { continue }
                    let activePitchClasses = ChromaExtractor.activePitchClasses(
                        from: samples,
                        sampleRate: buffer.format.sampleRate,
                        referencePitch: referencePitch
                    )
                    if let event = segmenter.process(activePitchClasses: activePitchClasses) {
                        continuation.yield(event)
                    }
                }
                continuation.finish()
            }

            continuation.onTermination = { [audioEngineController] _ in
                consumerTask.cancel()
                audioEngineController.stop()
            }
        }
    }
}
