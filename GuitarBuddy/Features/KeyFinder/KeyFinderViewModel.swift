import Foundation
import Observation

@Observable
final class KeyFinderViewModel {
    var selectedRoot: PitchClass?
    var selectedQuality: ChordQuality = .major
    private(set) var chords: [Chord] = []
    private(set) var isPlaying = false
    private(set) var playbackErrorMessage: String?

    private let chordPlayer: ChordSequencePlaying
    private var playbackTask: Task<Void, Never>?
    private var currentPlaybackID: UUID?

    var result: KeyMatchResult {
        KeyFinder.findKey(for: chords)
    }

    init(chordPlayer: ChordSequencePlaying = ChordSequencePlayer()) {
        self.chordPlayer = chordPlayer
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
        stopPlayback()
        chords.removeAll()
        selectedRoot = nil
        selectedQuality = .major
    }

    func playChords() {
        guard !isPlaying, !chords.isEmpty else { return }
        isPlaying = true
        playbackErrorMessage = nil
        let chordsToPlay = chords
        let playbackID = UUID()
        currentPlaybackID = playbackID
        playbackTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.chordPlayer.play(chordsToPlay)
            } catch {
                AppLogger.keyFinder.error("Chord playback failed: \(error.localizedDescription, privacy: .public)")
                // A newer playChords() call may have superseded this one while it was awaiting
                // playback (e.g. Clear + Play in quick succession); only the still-current
                // playback should be allowed to update isPlaying/playbackErrorMessage.
                guard self.currentPlaybackID == playbackID else { return }
                self.playbackErrorMessage = error.localizedDescription
            }
            guard self.currentPlaybackID == playbackID else { return }
            self.isPlaying = false
        }
    }

    func stopPlayback() {
        currentPlaybackID = nil
        chordPlayer.stop()
        playbackTask?.cancel()
        playbackTask = nil
        isPlaying = false
    }
}
