import Foundation

/// Matches a set of simultaneously-sounding pitch classes (e.g. from a strummed chord) against
/// every (root, quality) template. Requires the entire template to be present in the active set
/// (tolerates extra noise/harmonics, not missing chord tones), and prefers the largest matching
/// template — a 7th chord's 4-note template outranks the 3-note major triad subset it also satisfies.
///
/// Pitch-class sets alone can't always identify a chord uniquely, since this has no notion of
/// which note is the bass/root — some qualities are transpositionally symmetric or overlap in
/// content (e.g. {E,G#,C} is simultaneously E/G#/C augmented; {A,D,E} is both A sus4 and D sus2).
/// When templates of equal size tie, the one whose root comes first in `PitchClass.allCases`
/// order wins — an arbitrary but deterministic and tested choice, not a claim of musical priority.
enum ChordRecognizer {
    static func recognizeChord(from activePitchClasses: Set<PitchClass>) -> Chord? {
        var best: (chord: Chord, templateSize: Int)?

        for root in PitchClass.allCases {
            for quality in ChordQuality.allCases {
                let template = pitchClasses(for: root, quality: quality)
                guard template.isSubset(of: activePitchClasses) else { continue }
                if best == nil || template.count > best!.templateSize {
                    best = (Chord(root: root, quality: quality), template.count)
                }
            }
        }

        return best?.chord
    }

    private static func pitchClasses(for root: PitchClass, quality: ChordQuality) -> Set<PitchClass> {
        Set(quality.intervals.map { root.applying(semitones: $0) })
    }
}
