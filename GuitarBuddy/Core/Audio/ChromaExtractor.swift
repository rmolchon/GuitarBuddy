import Foundation

/// Detects which pitch classes are simultaneously sounding in a buffer (e.g. a strummed chord),
/// unlike `PitchDetector`'s YIN algorithm which finds a single fundamental. Guitar chords live in
/// a known, bounded set of candidate frequencies (12 pitch classes across a few octaves), so this
/// uses the Goertzel algorithm — efficient for detecting energy at a small set of known target
/// frequencies (the same reason it's used for DTMF/telephony tone detection) — rather than a full FFT.
enum ChromaExtractor {
    static let octaveRange = 2...5
    /// A pitch class counts as active when its loudest note reaches this fraction of the overall loudest.
    static let defaultEnergyThresholdRatio = 0.3
    private static let minimumRMS = SignalEnergy.defaultMinimumRMS

    /// One candidate note (a pitch class in a specific octave) and its measured magnitude.
    private struct NoteBin {
        let pitchClass: PitchClass
        let magnitude: Double
    }

    static func activePitchClasses(
        from samples: [Float],
        sampleRate: Double,
        referencePitch: Double = FrequencyToNote.standardReferencePitch,
        energyThresholdRatio: Double = defaultEnergyThresholdRatio
    ) -> Set<PitchClass> {
        guard SignalEnergy.hasSufficientEnergy(samples, minimumRMS: minimumRMS) else { return [] }

        let bins = noteBins(samples: samples, sampleRate: sampleRate, referencePitch: referencePitch)

        // Each pitch class is scored by its single loudest note, not the sum across octaves.
        // Summing let a doubled root (C3 + C4 + C5 in an open C chord) swamp the lone G or the
        // lone third of an E major, so those chord tones fell under the threshold.
        var chroma = [Double](repeating: 0, count: PitchClass.allCases.count)
        for bin in bins {
            chroma[bin.pitchClass.rawValue] = max(chroma[bin.pitchClass.rawValue], bin.magnitude)
        }
        guard let maxMagnitude = chroma.max(), maxMagnitude > 0 else { return [] }
        let threshold = maxMagnitude * energyThresholdRatio

        return Set(
            chroma.enumerated()
                .filter { $0.element >= threshold }
                .compactMap { PitchClass(rawValue: $0.offset) }
        )
    }

    /// Goertzel magnitude (amplitude-like, not squared energy) at every candidate note.
    private static func noteBins(samples: [Float], sampleRate: Double, referencePitch: Double) -> [NoteBin] {
        octaveRange.flatMap { octave in
            PitchClass.allCases.compactMap { pitchClass -> NoteBin? in
                let frequency = FrequencyToNote.frequency(forPitchClass: pitchClass, octave: octave, referencePitch: referencePitch)
                guard frequency < sampleRate / 2 else { return nil }
                let energy = goertzelEnergy(samples: samples, targetFrequency: frequency, sampleRate: sampleRate)
                return NoteBin(pitchClass: pitchClass, magnitude: energy.squareRoot())
            }
        }
    }

    private static func goertzelEnergy(samples: [Float], targetFrequency: Double, sampleRate: Double) -> Double {
        let omega = 2 * Double.pi * targetFrequency / sampleRate
        let coefficient = 2 * cos(omega)
        var s0 = 0.0
        var s1 = 0.0
        var s2 = 0.0
        for sample in samples {
            s0 = Double(sample) + coefficient * s1 - s2
            s2 = s1
            s1 = s0
        }
        let real = s1 - s2 * cos(omega)
        let imaginary = s2 * sin(omega)
        return real * real + imaginary * imaginary
    }
}
