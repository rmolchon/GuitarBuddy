import Foundation
import Observation

@Observable
final class KeyFinderViewModel {
    var chordInput: String = ""
    private(set) var chords: [Chord] = []
    private(set) var invalidInputMessage: String?

    var result: KeyMatchResult {
        KeyFinder.findKey(for: chords)
    }

    func addChord() {
        let trimmed = chordInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let chord = Chord.parse(trimmed) else {
            invalidInputMessage = "\"\(trimmed)\" isn't a recognized chord symbol."
            return
        }
        chords.append(chord)
        chordInput = ""
        invalidInputMessage = nil
    }

    func removeChord(at index: Int) {
        guard chords.indices.contains(index) else { return }
        chords.remove(at: index)
    }

    func clear() {
        chords.removeAll()
        chordInput = ""
        invalidInputMessage = nil
    }
}
