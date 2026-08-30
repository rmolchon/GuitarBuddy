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
        let segmenter = StrumSegmenter()
        let referencePitch = referencePitch
        return AudioTranscriptionStreamBuilder.makeStream(
            audioEngineController: audioEngineController,
            rawStream: { $0.frameStream },
            logger: AppLogger.transcribe
        ) { frame in
            let activePitchClasses = ChromaExtractor.activePitchClasses(
                from: frame.samples,
                sampleRate: frame.sampleRate,
                referencePitch: referencePitch
            )
            return segmenter.process(activePitchClasses: activePitchClasses)
        }
    }
}
