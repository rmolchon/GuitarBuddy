enum AudioSource {
    case microphone
}

struct TranscriptionEvent: Equatable {
    let note: DetectedNote
}

protocol AudioTranscriptionService {
    func transcribe(audioSource: AudioSource) -> AsyncThrowingStream<TranscriptionEvent, Error>
}
