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
        let segmenter = HumNoteSegmenter(referencePitch: referencePitch)
        return AudioTranscriptionStreamBuilder.makeStream(
            audioEngineController: audioEngineController,
            rawStream: { $0.pitchStream },
            logger: AppLogger.humMode,
            process: segmenter.process(frequency:)
        )
    }
}
