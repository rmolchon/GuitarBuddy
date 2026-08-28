import Foundation

struct PitchDetector: PitchDetecting {
    private let threshold: Double
    private let minFrequency: Double
    private let maxFrequency: Double
    private let minimumRMS: Float

    init(
        threshold: Double = 0.15,
        minFrequency: Double = 60.0,
        maxFrequency: Double = 1500.0,
        minimumRMS: Float = 0.01
    ) {
        self.threshold = threshold
        self.minFrequency = minFrequency
        self.maxFrequency = maxFrequency
        self.minimumRMS = minimumRMS
    }

    func detectPitch(from samples: [Float], sampleRate: Double) -> Double? {
        guard SignalEnergy.hasSufficientEnergy(samples, minimumRMS: minimumRMS) else { return nil }

        let tauMin = max(1, Int(sampleRate / maxFrequency))
        let tauMax = min(samples.count / 2, Int(sampleRate / minFrequency))
        guard tauMax > tauMin else { return nil }

        let cmndf = cumulativeMeanNormalizedDifference(samples: samples, tauMax: tauMax)
        guard let tau = absoluteThresholdTau(cmndf: cmndf, tauMin: tauMin, tauMax: tauMax) else {
            return nil
        }

        let refinedTau = parabolicInterpolation(cmndf: cmndf, tau: tau)
        return sampleRate / refinedTau
    }

    private func cumulativeMeanNormalizedDifference(samples: [Float], tauMax: Int) -> [Double] {
        var difference = [Double](repeating: 0, count: tauMax + 1)
        for tau in 1...tauMax {
            var sum: Double = 0
            for j in 0..<(samples.count - tau) {
                let delta = Double(samples[j] - samples[j + tau])
                sum += delta * delta
            }
            difference[tau] = sum
        }

        var cmndf = [Double](repeating: 1, count: tauMax + 1)
        var runningSum: Double = 0
        for tau in 1...tauMax {
            runningSum += difference[tau]
            cmndf[tau] = runningSum > 0 ? difference[tau] * Double(tau) / runningSum : 1
        }
        return cmndf
    }

    private func absoluteThresholdTau(cmndf: [Double], tauMin: Int, tauMax: Int) -> Int? {
        var tau = tauMin
        while tau <= tauMax {
            if cmndf[tau] < threshold {
                while tau + 1 <= tauMax && cmndf[tau + 1] < cmndf[tau] {
                    tau += 1
                }
                return tau
            }
            tau += 1
        }
        return nil
    }

    private func parabolicInterpolation(cmndf: [Double], tau: Int) -> Double {
        guard tau > 0, tau < cmndf.count - 1 else { return Double(tau) }
        let s0 = cmndf[tau - 1]
        let s1 = cmndf[tau]
        let s2 = cmndf[tau + 1]
        let denominator = 2 * s1 - s2 - s0
        guard denominator != 0 else { return Double(tau) }
        let shift = (s2 - s0) / (2 * denominator)
        return Double(tau) + shift
    }
}
