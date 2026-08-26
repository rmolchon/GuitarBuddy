import Foundation

/// Collapses a jittery active-pitch-class stream into discrete chord-onset events using a
/// `FrameDebouncer`, mapping each frame's active pitch classes to a `Chord` via `ChordRecognizer`
/// first. An unrecognizable pitch-class cluster is treated the same as silence (`nil`), since
/// there's no `Chord` value to hold a candidate for.
final class StrumSegmenter {
    private let debouncer: FrameDebouncer<Chord>

    init(requiredConsecutiveFrames: Int = 2) {
        self.debouncer = FrameDebouncer(requiredConsecutiveFrames: requiredConsecutiveFrames, areEqual: ==)
    }

    func process(activePitchClasses: Set<PitchClass>) -> TranscriptionEvent? {
        let chord = ChordRecognizer.recognizeChord(from: activePitchClasses)
        return debouncer.process(chord).map(TranscriptionEvent.chord)
    }
}
