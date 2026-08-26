import Foundation

/// Detects which pitch classes are simultaneously sounding in a buffer (e.g. a strummed chord),
/// unlike `PitchDetector`'s YIN algorithm which finds a single fundamental. Guitar chords live in
/// a known, bounded set of candidate frequencies (12 pitch classes across a few octaves), so this
/// uses the Goertzel algorithm — efficient for detecting energy at a small set of known target
/// frequencies (the same reason it's used for DTMF/telephony tone detection) — rather than a full FFT.
enum ChromaExtractor {
    private static let octaveRange = 2...5
    private static let minimumRMS: Float = 0.01

    static func activePitchClasses(
        from samples: [Float],
        sampleRate: Double,
        referencePitch: Double = 440.0,
        energyThresholdRatio: Double = 0.3
    ) -> Set<PitchClass> {
        guard hasSufficientEnergy(samples) else { return [] }

        var chromaEnergy = [Double](repeating: 0, count: PitchClass.allCases.count)
        for octave in octaveRange {
            for pitchClass in PitchClass.allCases {
                let frequency = FrequencyToNote.frequency(forPitchClass: pitchClass, octave: octave, referencePitch: referencePitch)
                guard frequency < sampleRate / 2 else { continue }
                chromaEnergy[pitchClass.rawValue] += goertzelEnergy(samples: samples, targetFrequency: frequency, sampleRate: sampleRate)
            }
        }

        guard let maxEnergy = chromaEnergy.max(), maxEnergy > 0 else { return [] }
        let threshold = maxEnergy * energyThresholdRatio

        return Set(
            chromaEnergy.enumerated()
                .filter { $0.element >= threshold }
                .compactMap { PitchClass(rawValue: $0.offset) }
        )
    }

    private static func hasSufficientEnergy(_ samples: [Float]) -> Bool {
        guard !samples.isEmpty else { return false }
        let sumOfSquares = samples.reduce(Float(0)) { $0 + $1 * $1 }
        let rms = sqrt(sumOfSquares / Float(samples.count))
        return rms >= minimumRMS
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
