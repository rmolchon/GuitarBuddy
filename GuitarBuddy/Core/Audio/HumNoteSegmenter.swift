import Foundation

/// Collapses a jittery, periodically-sampled frequency stream into discrete note-onset events.
/// A candidate note must repeat for `requiredConsecutiveFrames` frames before it's confirmed
/// (debounces vibrato/breath blips), and only a change from the last confirmed note emits an
/// event. Silence resets all state so the same pitch hummed again after a pause re-emits.
final class HumNoteSegmenter {
    private let referencePitch: Double
    private let requiredConsecutiveFrames: Int

    private var candidateNote: DetectedNote?
    private var candidateStreak = 0
    private var confirmedNote: DetectedNote?

    init(referencePitch: Double = 440.0, requiredConsecutiveFrames: Int = 2) {
        self.referencePitch = referencePitch
        self.requiredConsecutiveFrames = requiredConsecutiveFrames
    }

    func process(frequency: Double?) -> TranscriptionEvent? {
        guard let frequency, let note = FrequencyToNote.note(forFrequency: frequency, referencePitch: referencePitch) else {
            reset()
            return nil
        }

        updateCandidate(with: note)

        guard candidateStreak >= requiredConsecutiveFrames, !matches(note, confirmedNote) else {
            return nil
        }

        confirmedNote = note
        return TranscriptionEvent(note: note)
    }

    private func updateCandidate(with note: DetectedNote) {
        if matches(note, candidateNote) {
            candidateStreak += 1
        } else {
            candidateNote = note
            candidateStreak = 1
        }
    }

    private func matches(_ lhs: DetectedNote, _ rhs: DetectedNote?) -> Bool {
        guard let rhs else { return false }
        return lhs.pitchClass == rhs.pitchClass && lhs.octave == rhs.octave
    }

    private func reset() {
        candidateNote = nil
        candidateStreak = 0
        confirmedNote = nil
    }
}
