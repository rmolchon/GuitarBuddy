final class TranscribeViewModel: TranscriptionCollectorViewModel<Chord> {
    var chords: [Chord] { items }

    init(transcriptionService: AudioTranscriptionService = StrumTranscriptionService()) {
        super.init(transcriptionService: transcriptionService, logger: AppLogger.transcribe) { event in
            guard case .chord(let chord) = event else { return nil }
            return chord
        }
    }
}
