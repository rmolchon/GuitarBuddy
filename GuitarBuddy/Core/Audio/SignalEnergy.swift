import Foundation

/// Shared RMS-energy gate used to skip near-silent buffers before running detection —
/// both `PitchDetector` (single-fundamental YIN) and `ChromaExtractor` (polyphonic Goertzel)
/// need the same cheap "is there anything here worth analyzing" check.
enum SignalEnergy {
    static func hasSufficientEnergy(_ samples: [Float], minimumRMS: Float) -> Bool {
        guard !samples.isEmpty else { return false }
        let sumOfSquares = samples.reduce(Float(0)) { $0 + $1 * $1 }
        let rms = sqrt(sumOfSquares / Float(samples.count))
        return rms >= minimumRMS
    }
}
