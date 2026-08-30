import Foundation

/// Maps a `Chord` to the actual Hz of each chord tone, one octave-aware step above `FrequencyToNote`:
/// `PitchClass.applying(semitones:)` wraps within a single octave, which would fold a chord's higher
/// tones back down instead of letting them ring above the root, so this walks each interval through
/// `FrequencyToNote.neighborNote` (which already handles the octave carry) before converting to Hz.
enum ChordFrequencies {
    static func frequencies(for chord: Chord, baseOctave: Int) -> [Double] {
        chord.quality.intervals.map { interval in
            let neighbor = FrequencyToNote.neighborNote(pitchClass: chord.root, octave: baseOctave, semitones: interval)
            return FrequencyToNote.frequency(forPitchClass: neighbor.pitchClass, octave: neighbor.octave)
        }
    }
}
