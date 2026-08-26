import Foundation
import Observation

@Observable
final class TranscribeViewModel {
    private let transcriptionService: AudioTranscriptionService
    private var transcriptionTask: Task<Void, Never>?

    private(set) var isListening = false
    private(set) var errorMessage: String?
    private(set) var chords: [Chord] = []

    init(transcriptionService: AudioTranscriptionService = StrumTranscriptionService()) {
        self.transcriptionService = transcriptionService
    }

    func start() {
        guard !isListening else { return }
        isListening = true
        errorMessage = nil
        let stream = transcriptionService.transcribe(audioSource: .microphone)
        transcriptionTask = Task { [weak self] in
            do {
                for try await event in stream {
                    if case .chord(let chord) = event {
                        self?.chords.append(chord)
                    }
                }
            } catch {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func stop() {
        transcriptionTask?.cancel()
        transcriptionTask = nil
        isListening = false
    }

    func clear() {
        chords.removeAll()
    }
}
