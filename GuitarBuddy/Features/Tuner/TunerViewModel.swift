import Foundation
import Observation

@Observable
final class TunerViewModel {
    private static let referencePitchKey = "referencePitch"

    private let makeAudioEngineController: () -> AudioEngineController
    private var audioEngineController: AudioEngineController?
    private var pitchTask: Task<Void, Never>?

    var selectedTuning: Tuning = .standard
    private(set) var isListening = false
    private(set) var isStarting = false
    private(set) var errorMessage: String?
    var lastDetectedFrequency: Double?

    var referencePitch: Double {
        get { UserDefaults.standard.object(forKey: Self.referencePitchKey) as? Double ?? 440.0 }
        set { UserDefaults.standard.set(newValue, forKey: Self.referencePitchKey) }
    }

    var detectedNote: DetectedNote? {
        guard let frequency = lastDetectedFrequency else { return nil }
        return FrequencyToNote.note(forFrequency: frequency, referencePitch: referencePitch)
    }

    var closestStringIndex: Int? {
        guard let frequency = lastDetectedFrequency else { return nil }
        return selectedTuning.stringFrequencies.indices.min { lhs, rhs in
            abs(log2(frequency / scaledTargetFrequency(at: lhs))) < abs(log2(frequency / scaledTargetFrequency(at: rhs)))
        }
    }

    var centsOffsetFromClosestString: Double? {
        guard let frequency = lastDetectedFrequency, let index = closestStringIndex else { return nil }
        return 1200 * log2(frequency / scaledTargetFrequency(at: index))
    }

    init(makeAudioEngineController: @escaping () -> AudioEngineController = { AudioEngineController() }) {
        self.makeAudioEngineController = makeAudioEngineController
    }

    func start() {
        guard !isListening, !isStarting else { return }
        isStarting = true
        errorMessage = nil
        let audioEngineController = makeAudioEngineController()
        self.audioEngineController = audioEngineController
        pitchTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await audioEngineController.start()
            } catch {
                AppLogger.tuner.error("Failed to start audio engine: \(error.localizedDescription, privacy: .public)")
                self.errorMessage = error.localizedDescription
                self.isStarting = false
                return
            }
            self.isStarting = false
            self.isListening = true
            let stream = audioEngineController.pitchStream
            for await pitch in stream {
                self.lastDetectedFrequency = pitch
            }
        }
    }

    func stop() {
        pitchTask?.cancel()
        pitchTask = nil
        audioEngineController?.stop()
        audioEngineController = nil
        isListening = false
        isStarting = false
        lastDetectedFrequency = nil
    }

    private func scaledTargetFrequency(at index: Int) -> Double {
        selectedTuning.stringFrequencies[index] * (referencePitch / 440.0)
    }
}
