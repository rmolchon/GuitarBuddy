enum AudioSource: Sendable {
    case microphone
}

enum TranscriptionEvent: Equatable, Sendable {
    case note(DetectedNote)
    case chord(Chord)
}

protocol AudioTranscriptionService: Sendable {
    func transcribe(audioSource: AudioSource) -> AsyncThrowingStream<TranscriptionEvent, Error>
}
