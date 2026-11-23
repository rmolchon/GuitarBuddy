import Foundation
import Observation

@MainActor
@Observable
final class TunerViewModel {
    private static let referencePitchKey = "referencePitch"

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let makeAudioEngineController: () -> AudioEngineController
    @ObservationIgnored private var audioEngineController: AudioEngineController?
    @ObservationIgnored private var pitchTask: Task<Void, Never>?
    @ObservationIgnored private var smoother = PitchSmoother()

    var selectedTuning: Tuning = .standard
    private(set) var isListening = false
    private(set) var isStarting = false
    private(set) var errorMessage: String?
    private(set) var lastDetectedFrequency: Double?

    /// Stored (not computed over `UserDefaults`) so `@Observable` tracks it; persisted on change.
    var referencePitch: Double {
        didSet { defaults.set(referencePitch, forKey: Self.referencePitchKey) }
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

    init(
        defaults: UserDefaults = .standard,
        makeAudioEngineController: @escaping () -> AudioEngineController = { AudioEngineController() }
    ) {
        self.defaults = defaults
        self.makeAudioEngineController = makeAudioEngineController
        self.referencePitch = defaults.object(forKey: Self.referencePitchKey) as? Double
            ?? FrequencyToNote.standardReferencePitch
    }

    /// Feeds one raw detector reading through the smoother into the displayed frequency.
    func ingest(pitch: Double?) {
        lastDetectedFrequency = smoother.push(pitch)
    }

    func start() {
        guard !isListening, !isStarting else { return }
        isStarting = true
        errorMessage = nil
        smoother = PitchSmoother()
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
                self.ingest(pitch: pitch)
            }

            // The stream also ends when the engine is torn down mid-session (interruption,
            // route loss, config change). Reset the button and surface any error so it
            // never sits on "Listening" with a dead engine.
            self.isListening = false
            self.lastDetectedFrequency = nil
            if let terminationError = audioEngineController.terminationError {
                AppLogger.tuner.warning("Audio session ended: \(terminationError.localizedDescription, privacy: .public)")
                self.errorMessage = terminationError.localizedDescription
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
        smoother = PitchSmoother()
        lastDetectedFrequency = nil
    }

    private func scaledTargetFrequency(at index: Int) -> Double {
        selectedTuning.stringFrequencies[index] * (referencePitch / FrequencyToNote.standardReferencePitch)
    }
}
