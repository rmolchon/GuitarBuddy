import Foundation

/// Collapses a jittery, periodically-sampled value stream into discrete change events.
/// A candidate value must repeat for `requiredConsecutiveFrames` frames before it's confirmed
/// (debounces transient blips), and only a change from the last confirmed value emits an event.
/// `nil` (silence/no-signal frames) resets all state, so the same value seen again after a gap
/// re-arms and re-emits.
final class FrameDebouncer<Value> {
    private let requiredConsecutiveFrames: Int
    private let areEqual: (Value, Value) -> Bool

    private var candidateValue: Value?
    private var candidateStreak = 0
    private var confirmedValue: Value?

    init(requiredConsecutiveFrames: Int = 2, areEqual: @escaping (Value, Value) -> Bool) {
        self.requiredConsecutiveFrames = requiredConsecutiveFrames
        self.areEqual = areEqual
    }

    func process(_ value: Value?) -> Value? {
        guard let value else {
            reset()
            return nil
        }

        updateCandidate(with: value)

        guard candidateStreak >= requiredConsecutiveFrames, !matches(value, confirmedValue) else {
            return nil
        }

        confirmedValue = value
        return value
    }

    private func updateCandidate(with value: Value) {
        if matches(value, candidateValue) {
            candidateStreak += 1
        } else {
            candidateValue = value
            candidateStreak = 1
        }
    }

    private func matches(_ lhs: Value, _ rhs: Value?) -> Bool {
        guard let rhs else { return false }
        return areEqual(lhs, rhs)
    }

    private func reset() {
        candidateValue = nil
        candidateStreak = 0
        confirmedValue = nil
    }
}
