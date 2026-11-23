import Foundation

/// Deterministic stand-in for real guitar/voice recordings: additive synthesis with the
/// properties that make real signals hard for DSP — a weak fundamental on wound strings,
/// harmonics that decay faster than the fundamental, a sharp attack transient, vibrato,
/// staggered strum onsets and background noise. Pure `[Float]`, no AVFoundation.
enum SyntheticInstrument {
    static let sampleRate: Double = 44100
    static let frameSize = 4096

    struct Timbre {
        /// Relative amplitude of harmonics 1, 2, 3...
        let harmonicAmplitudes: [Double]
        /// Seconds for harmonic 1 to fall to 1/e; higher harmonics decay proportionally faster.
        let decaySeconds: Double

        /// Wound low string: fundamental is weaker than the 2nd harmonic, the case YIN must survive.
        static let woundString = Timbre(harmonicAmplitudes: [0.35, 0.9, 0.6, 0.4, 0.25, 0.15], decaySeconds: 1.2)
        /// Plain treble string: strong fundamental.
        static let plainString = Timbre(harmonicAmplitudes: [1.0, 0.5, 0.3, 0.15, 0.08], decaySeconds: 0.9)
        /// Sung vowel: sustained, no decay.
        static let voice = Timbre(harmonicAmplitudes: [1.0, 0.6, 0.35, 0.2], decaySeconds: .infinity)

        static func forFrequency(_ frequency: Double) -> Timbre {
            frequency < 200 ? woundString : plainString
        }
    }

    /// One note. `vibratoCents` is the peak pitch deviation of a 5 Hz vibrato.
    static func note(
        frequency: Double,
        duration: Double,
        timbre: Timbre,
        vibratoCents: Double = 0,
        amplitude: Double = 0.5
    ) -> [Float] {
        let count = Int(sampleRate * duration)
        let attackSamples = Int(sampleRate * 0.005)
        var phase = 0.0
        var samples = [Float](repeating: 0, count: count)
        for index in 0..<count {
            let time = Double(index) / sampleRate
            let vibrato = vibratoCents * sin(2 * .pi * 5 * time)
            let instantaneous = frequency * pow(2, vibrato / 1200)
            phase += 2 * .pi * instantaneous / sampleRate
            var value = 0.0
            for (offset, harmonicAmplitude) in timbre.harmonicAmplitudes.enumerated() {
                let harmonic = Double(offset + 1)
                let decay = exp(-time * harmonic / timbre.decaySeconds)
                value += harmonicAmplitude * decay * sin(phase * harmonic)
            }
            let attack = min(1, Double(index) / Double(max(1, attackSamples)))
            samples[index] = Float(amplitude * attack * value / Double(timbre.harmonicAmplitudes.count) * 2)
        }
        return samples
    }

    /// A strum: each string starts `stagger` seconds after the previous, summed.
    static func strum(frequencies: [Double], duration: Double, stagger: Double = 0.012) -> [Float] {
        let count = Int(sampleRate * duration)
        var mix = [Float](repeating: 0, count: count)
        for (stringIndex, frequency) in frequencies.enumerated() {
            let start = Int(sampleRate * stagger * Double(stringIndex))
            let pluck = note(frequency: frequency, duration: duration, timbre: .forFrequency(frequency), amplitude: 0.25)
            for index in 0..<(count - start) {
                mix[start + index] += pluck[index]
            }
        }
        return mix
    }

    static func silence(duration: Double) -> [Float] {
        [Float](repeating: 0, count: Int(sampleRate * duration))
    }

    /// Adds deterministic uniform noise at the given peak amplitude.
    static func addingNoise(to samples: [Float], amplitude: Float, seed: UInt64 = 7) -> [Float] {
        var state = seed
        return samples.map { sample in
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let unit = Float(Double(state >> 11) / Double(1 << 53)) * 2 - 1
            return sample + unit * amplitude
        }
    }

    /// Splits a signal into consecutive tap-sized frames, dropping a trailing partial frame —
    /// mirroring the 4096-sample buffers `AudioEngineController` delivers.
    static func frames(of samples: [Float], size: Int = frameSize) -> [[Float]] {
        stride(from: 0, through: samples.count - size, by: size).map { Array(samples[$0..<($0 + size)]) }
    }

    static func cents(from reference: Double, to measured: Double) -> Double {
        1200 * log2(measured / reference)
    }
}
