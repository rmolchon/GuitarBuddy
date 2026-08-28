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
            rawStream: { $0.bufferStream },
            logger: AppLogger.transcribe
        ) { buffer in
            guard let samples = AudioEngineController.samples(from: buffer) else { return nil }
            let activePitchClasses = ChromaExtractor.activePitchClasses(
                from: samples,
                sampleRate: buffer.format.sampleRate,
                referencePitch: referencePitch
            )
            return segmenter.process(activePitchClasses: activePitchClasses)
        }
    }
}
