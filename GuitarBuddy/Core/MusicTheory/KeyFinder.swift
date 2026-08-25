struct KeyMatchResult: Equatable {
    let key: MusicalKey?
    let confidence: Double
    let isAmbiguous: Bool
}

enum KeyFinder {
    static func findKey(for chords: [Chord]) -> KeyMatchResult {
        guard !chords.isEmpty else {
            return KeyMatchResult(key: nil, confidence: 0, isAmbiguous: true)
        }

        let scores = PitchClass.allCases.map { tonic in
            (tonic: tonic, score: diatonicScore(tonic: tonic, chords: chords))
        }
        let maxScore = scores.map(\.score).max() ?? 0
        var candidates = scores.filter { $0.score == maxScore }.map(\.tonic)

        if candidates.count > 1 {
            let survivors = candidates.filter { tonicOrRelativeMinorPresent(tonic: $0, chords: chords) }
            if !survivors.isEmpty { candidates = survivors }
        }

        if candidates.count > 1 {
            let survivors = candidates.filter { dominantPresent(tonic: $0, chords: chords) }
            if !survivors.isEmpty { candidates = survivors }
        }

        guard candidates.count == 1, let tonic = candidates.first else {
            return KeyMatchResult(key: nil, confidence: maxScore, isAmbiguous: true)
        }

        return KeyMatchResult(key: MusicalKey(tonic: tonic), confidence: maxScore, isAmbiguous: false)
    }

    private static func diatonicScore(tonic: PitchClass, chords: [Chord]) -> Double {
        let slots = KeySignatureTable.diatonicSlots(for: tonic)
        let matchCount = chords.filter { chord in
            slots.contains { $0.root == chord.root && $0.family == chord.quality.family }
        }.count
        return Double(matchCount) / Double(chords.count)
    }

    private static func tonicOrRelativeMinorPresent(tonic: PitchClass, chords: [Chord]) -> Bool {
        let relativeMinorRoot = tonic.applying(semitones: 9)
        return chords.contains { chord in
            (chord.root == tonic && chord.quality.family == .majorFamily) ||
            (chord.root == relativeMinorRoot && chord.quality.family == .minorFamily)
        }
    }

    private static func dominantPresent(tonic: PitchClass, chords: [Chord]) -> Bool {
        let dominantRoot = tonic.applying(semitones: 7)
        return chords.contains { chord in
            chord.root == dominantRoot && (chord.quality == .major || chord.quality == .dominant7)
        }
    }
}
