import Foundation
import Observation

@Observable
final class KeyFinderViewModel {
    var selectedRoot: PitchClass?
    var selectedQuality: ChordQuality = .major
    private(set) var chords: [Chord] = []

    var result: KeyMatchResult {
        KeyFinder.findKey(for: chords)
    }

    func addChord() {
        guard let selectedRoot else { return }
        chords.append(Chord(root: selectedRoot, quality: selectedQuality))
        self.selectedRoot = nil
        selectedQuality = .major
    }

    func removeChord(at index: Int) {
        guard chords.indices.contains(index) else { return }
        chords.remove(at: index)
    }

    func clear() {
        chords.removeAll()
        selectedRoot = nil
        selectedQuality = .major
    }
}
