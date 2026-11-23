import Foundation

/// Stabilises the raw ~93 ms YIN readings for display: a sliding-window median rejects
/// single-frame outliers (e.g. an octave-error blip), and a short hold keeps the last value
/// across brief detection dropouts so the needle doesn't flicker to "no signal" between
/// plucks. Sustained silence clears everything so the next note starts fresh.
///
/// A value type with a mutating `push`, owned by one consumer (the tuner's stream loop).
struct PitchSmoother {
    static let defaultWindowSize = 5
    static let defaultHoldFrames = 3

    private let windowSize: Int
    private let holdFrames: Int
    private var window: [Double] = []
    private var consecutiveMisses = 0

    init(windowSize: Int = defaultWindowSize, holdFrames: Int = defaultHoldFrames) {
        self.windowSize = max(1, windowSize)
        self.holdFrames = max(0, holdFrames)
    }

    /// Feeds one raw reading (`nil` = nothing detected) and returns the smoothed value.
    mutating func push(_ frequency: Double?) -> Double? {
        guard let frequency else {
            consecutiveMisses += 1
            guard consecutiveMisses <= holdFrames else {
                window.removeAll()
                return nil
            }
            return median
        }
        consecutiveMisses = 0
        window.append(frequency)
        if window.count > windowSize {
            window.removeFirst(window.count - windowSize)
        }
        return median
    }

    private var median: Double? {
        guard !window.isEmpty else { return nil }
        let sorted = window.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}
