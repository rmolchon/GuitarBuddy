enum AudioSource {
    case microphone
}

enum TranscriptionEvent: Equatable {
    case note(DetectedNote)
    case chord(Chord)
}

protocol AudioTranscriptionService {
    func transcribe(audioSource: AudioSource) -> AsyncThrowingStream<TranscriptionEvent, Error>
}
