import Foundation
import Observation
import os

/// Shared start/stop/collect lifecycle for view models that turn an `AudioTranscriptionService`
/// stream into a growing list of one `TranscriptionEvent` case. `HumModeViewModel` and
/// `TranscribeViewModel` differ only in which case they unwrap and what they call the resulting
/// array — this factors out the task management, error handling, and `clear()` they'd otherwise
/// duplicate. `items` is settable only from this file, so subclasses can read but not mutate it
/// directly; they expose it under a feature-specific name (`notes`, `chords`).
@Observable
class TranscriptionCollectorViewModel<Output> {
    private let transcriptionService: AudioTranscriptionService
    private let logger: Logger
    private let extractOutput: (TranscriptionEvent) -> Output?
    private var transcriptionTask: Task<Void, Never>?

    private(set) var isListening = false
    private(set) var errorMessage: String?
    private(set) var items: [Output] = []

    init(
        transcriptionService: AudioTranscriptionService,
        logger: Logger,
        extractOutput: @escaping (TranscriptionEvent) -> Output?
    ) {
        self.transcriptionService = transcriptionService
        self.logger = logger
        self.extractOutput = extractOutput
    }

    func start() {
        guard !isListening else { return }
        isListening = true
        errorMessage = nil
        let stream = transcriptionService.transcribe(audioSource: .microphone)
        transcriptionTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await event in stream {
                    if let output = self.extractOutput(event) {
                        self.items.append(output)
                    }
                }
            } catch {
                self.logger.error("Transcription stream failed: \(error.localizedDescription, privacy: .public)")
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func stop() {
        transcriptionTask?.cancel()
        transcriptionTask = nil
        isListening = false
    }

    func clear() {
        items.removeAll()
    }
}
