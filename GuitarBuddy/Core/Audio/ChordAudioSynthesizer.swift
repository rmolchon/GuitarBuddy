import Foundation

/// Pure sample generation for chord playback: sums sine waves at each chord tone's frequency,
/// applies a short linear fade in/out to avoid clicks at buffer boundaries, and inserts a brief
/// silence between chords. No AVFoundation dependency, so this stays exhaustively unit-testable —
/// `ChordSequencePlayer` is the thin AVAudioEngine wrapper that turns this into a playable buffer.
enum ChordAudioSynthesizer {
    static let sampleRate = 44_100.0
    static let chordDuration = 0.9
    static let gapDuration = 0.15
    static let baseOctave = 3

    private static let amplitude: Float = 0.2
    private static let fadeDuration = 0.02

    static func samples(for chords: [Chord]) -> [Float] {
        var output: [Float] = []
        for (index, chord) in chords.enumerated() {
            output.append(contentsOf: samples(forChord: chord))
            if index < chords.count - 1 {
                output.append(contentsOf: silence(duration: gapDuration))
            }
        }
        return output
    }

    private static func samples(forChord chord: Chord) -> [Float] {
        let frequencies = ChordFrequencies.frequencies(for: chord, baseOctave: baseOctave)
        let frameCount = Int(chordDuration * sampleRate)
        let fadeFrames = Int(fadeDuration * sampleRate)

        return (0..<frameCount).map { frame in
            let time = Double(frame) / sampleRate
            let sum = frequencies.reduce(0.0) { $0 + sin(2 * .pi * $1 * time) }
            let normalized = Float(sum / Double(frequencies.count)) * amplitude
            return normalized * envelope(atFrame: frame, frameCount: frameCount, fadeFrames: fadeFrames)
        }
    }

    private static func envelope(atFrame frame: Int, frameCount: Int, fadeFrames: Int) -> Float {
        guard fadeFrames > 0 else { return 1 }
        if frame < fadeFrames { return Float(frame) / Float(fadeFrames) }
        if frame >= frameCount - fadeFrames { return Float(frameCount - frame) / Float(fadeFrames) }
        return 1
    }

    private static func silence(duration: Double) -> [Float] {
        Array(repeating: 0, count: Int(duration * sampleRate))
    }
}
