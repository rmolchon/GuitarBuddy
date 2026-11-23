import Foundation

/// Collapses a jittery frequency stream into discrete note-onset events using a `FrameDebouncer`,
/// mapping raw frequency readings to notes via `FrequencyToNote` first. Notes are compared by
/// `pitchClass`/`octave` only (not full `Equatable`), since `cents` jitters every frame.
///
/// `@unchecked Sendable` for the same single-consumer reason as `FrameDebouncer`.
final class HumNoteSegmenter: @unchecked Sendable {
    private let referencePitch: Double
    private let debouncer: FrameDebouncer<DetectedNote>

    init(referencePitch: Double = 440.0, requiredConsecutiveFrames: Int = 2) {
        self.referencePitch = referencePitch
        self.debouncer = FrameDebouncer(requiredConsecutiveFrames: requiredConsecutiveFrames) { lhs, rhs in
            lhs.pitchClass == rhs.pitchClass && lhs.octave == rhs.octave
        }
    }

    func process(frequency: Double?) -> TranscriptionEvent? {
        let note = frequency.flatMap { FrequencyToNote.note(forFrequency: $0, referencePitch: referencePitch) }
        return debouncer.process(note).map(TranscriptionEvent.note)
    }
}
