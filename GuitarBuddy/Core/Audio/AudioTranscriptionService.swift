enum AudioSource {
    case microphone
}

struct TranscriptionEvent {}

protocol AudioTranscriptionService {
    func transcribe(audioSource: AudioSource) -> AsyncThrowingStream<TranscriptionEvent, Error>
}
