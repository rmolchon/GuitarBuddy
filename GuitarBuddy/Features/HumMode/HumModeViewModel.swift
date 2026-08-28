final class HumModeViewModel: TranscriptionCollectorViewModel<DetectedNote> {
    var notes: [DetectedNote] { items }

    init(transcriptionService: AudioTranscriptionService = HumTranscriptionService()) {
        super.init(transcriptionService: transcriptionService, logger: AppLogger.humMode) { event in
            guard case .note(let note) = event else { return nil }
            return note
        }
    }
}
