import XCTest
@testable import GuitarBuddy

@MainActor
final class KeyFinderViewModelTests: XCTestCase {
    func test_addChordDoesNothingWhenNoRootIsSelected() {
        // Arrange
        let viewModel = KeyFinderViewModel()

        // Act
        viewModel.addChord()

        // Assert
        XCTAssertTrue(viewModel.chords.isEmpty)
    }

    func test_addChordAppendsChordBuiltFromSelectedRootAndQuality() {
        // Arrange
        let viewModel = KeyFinderViewModel()
        viewModel.selectedRoot = .a
        viewModel.selectedQuality = .minor

        // Act
        viewModel.addChord()

        // Assert
        XCTAssertEqual(viewModel.chords, [Chord(root: .a, quality: .minor)])
    }

    func test_addChordDefaultsToMajorQualityWhenUnchanged() {
        // Arrange
        let viewModel = KeyFinderViewModel()
        viewModel.selectedRoot = .c

        // Act
        viewModel.addChord()

        // Assert
        XCTAssertEqual(viewModel.chords, [Chord(root: .c, quality: .major)])
    }

    func test_addChordResetsSelectionAfterAdding() {
        // Arrange
        let viewModel = KeyFinderViewModel()
        viewModel.selectedRoot = .g
        viewModel.selectedQuality = .dominant7

        // Act
        viewModel.addChord()

        // Assert
        XCTAssertNil(viewModel.selectedRoot)
        XCTAssertEqual(viewModel.selectedQuality, .major)
    }

    func test_addChordAllowsAddingTheSameChordMultipleTimes() {
        // Arrange
        let viewModel = KeyFinderViewModel()

        // Act
        viewModel.selectedRoot = .c
        viewModel.addChord()
        viewModel.selectedRoot = .c
        viewModel.addChord()

        // Assert
        XCTAssertEqual(viewModel.chords, [Chord(root: .c, quality: .major), Chord(root: .c, quality: .major)])
    }

    func test_removeChordAtValidIndexRemovesThatChord() {
        // Arrange
        let viewModel = KeyFinderViewModel()
        viewModel.selectedRoot = .c
        viewModel.addChord()
        viewModel.selectedRoot = .a
        viewModel.selectedQuality = .minor
        viewModel.addChord()

        // Act
        viewModel.removeChord(at: 0)

        // Assert
        XCTAssertEqual(viewModel.chords, [Chord(root: .a, quality: .minor)])
    }

    func test_removeChordAtInvalidIndexDoesNothing() {
        // Arrange
        let viewModel = KeyFinderViewModel()
        viewModel.selectedRoot = .c
        viewModel.addChord()

        // Act
        viewModel.removeChord(at: 5)

        // Assert
        XCTAssertEqual(viewModel.chords, [Chord(root: .c, quality: .major)])
    }

    func test_clearRemovesAllChordsAndResetsSelection() {
        // Arrange
        let viewModel = KeyFinderViewModel()
        viewModel.selectedRoot = .a
        viewModel.selectedQuality = .minor
        viewModel.addChord()
        viewModel.selectedRoot = .g

        // Act
        viewModel.clear()

        // Assert
        XCTAssertTrue(viewModel.chords.isEmpty)
        XCTAssertNil(viewModel.selectedRoot)
        XCTAssertEqual(viewModel.selectedQuality, .major)
    }

    func test_resultReflectsCurrentChordsViaKeyFinder() {
        // Arrange
        let viewModel = KeyFinderViewModel()
        viewModel.selectedRoot = .c
        viewModel.addChord()
        viewModel.selectedRoot = .a
        viewModel.selectedQuality = .minor
        viewModel.addChord()
        viewModel.selectedRoot = .f
        viewModel.addChord()
        viewModel.selectedRoot = .g
        viewModel.addChord()

        // Act
        let result = viewModel.result

        // Assert
        XCTAssertEqual(result, KeyFinder.findKey(for: viewModel.chords))
    }

    func test_playChordsSetsIsPlayingImmediatelyAndPassesTheCurrentChords() async {
        // Arrange
        let fake = FakeChordSequencePlayer()
        let viewModel = KeyFinderViewModel(chordPlayer: fake)
        viewModel.selectedRoot = .c
        viewModel.addChord()

        // Act
        viewModel.playChords()

        // Assert
        XCTAssertTrue(viewModel.isPlaying)
        await waitUntil { !fake.playedChordSequences.isEmpty }
        XCTAssertEqual(fake.playedChordSequences, [[Chord(root: .c, quality: .major)]])
        fake.finishPlayback()
    }

    func test_playChordsDoesNothingWhenNoChordsHaveBeenAdded() {
        // Arrange
        let fake = FakeChordSequencePlayer()
        let viewModel = KeyFinderViewModel(chordPlayer: fake)

        // Act
        viewModel.playChords()

        // Assert
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertTrue(fake.playedChordSequences.isEmpty)
    }

    func test_playChordsIgnoresARepeatTapWhileAlreadyPlaying() async {
        // Arrange
        let fake = FakeChordSequencePlayer()
        let viewModel = KeyFinderViewModel(chordPlayer: fake)
        viewModel.selectedRoot = .c
        viewModel.addChord()

        // Act
        viewModel.playChords()
        viewModel.playChords()

        // Assert
        await waitUntil { !fake.playedChordSequences.isEmpty }
        XCTAssertEqual(fake.playedChordSequences.count, 1)
        fake.finishPlayback()
    }

    func test_isPlayingBecomesFalseOncePlaybackCompletes() async {
        // Arrange
        let fake = FakeChordSequencePlayer()
        let viewModel = KeyFinderViewModel(chordPlayer: fake)
        viewModel.selectedRoot = .c
        viewModel.addChord()

        // Act
        viewModel.playChords()
        fake.finishPlayback()

        // Assert
        await waitUntil { !viewModel.isPlaying }
    }

    func test_playbackErrorMessageIsSetWhenThePlayerThrows() async {
        // Arrange
        let fake = FakeChordSequencePlayer()
        fake.errorToThrow = ChordPlaybackTestError.engineUnavailable
        let viewModel = KeyFinderViewModel(chordPlayer: fake)
        viewModel.selectedRoot = .c
        viewModel.addChord()

        // Act
        viewModel.playChords()

        // Assert
        await waitUntil { viewModel.playbackErrorMessage != nil }
        XCTAssertFalse(viewModel.isPlaying)
    }

    func test_stopPlaybackStopsThePlayerAndResetsIsPlaying() async {
        // Arrange
        let fake = FakeChordSequencePlayer()
        let viewModel = KeyFinderViewModel(chordPlayer: fake)
        viewModel.selectedRoot = .c
        viewModel.addChord()
        viewModel.playChords()
        await waitUntil { !fake.playedChordSequences.isEmpty }

        // Act
        viewModel.stopPlayback()

        // Assert
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(fake.stopCallCount, 1)
        fake.finishPlayback()
    }

    func test_clearAlsoStopsAnyInProgressPlayback() async {
        // Arrange
        let fake = FakeChordSequencePlayer()
        let viewModel = KeyFinderViewModel(chordPlayer: fake)
        viewModel.selectedRoot = .c
        viewModel.addChord()
        viewModel.playChords()
        await waitUntil { !fake.playedChordSequences.isEmpty }

        // Act
        viewModel.clear()

        // Assert
        XCTAssertEqual(fake.stopCallCount, 1)
        XCTAssertTrue(viewModel.chords.isEmpty)
        fake.finishPlayback()
    }

    func test_aStalePlaybackTaskDoesNotOverwriteANewerOnesState() async {
        // Arrange: start playing, stop before it completes (e.g. a Clear tap mid-playback), then
        // immediately start a second, still-in-flight playback.
        let fake = FakeChordSequencePlayer()
        let viewModel = KeyFinderViewModel(chordPlayer: fake)
        viewModel.selectedRoot = .c
        viewModel.addChord()
        viewModel.playChords()
        await waitUntil { fake.playedChordSequences.count == 1 }
        viewModel.stopPlayback()

        viewModel.selectedRoot = .g
        viewModel.addChord()
        viewModel.playChords()
        await waitUntil { fake.playedChordSequences.count == 2 }

        // Act: the stopped first playback's underlying task finally completes late, after the
        // second playback has already started.
        fake.finishPlayback(at: 0)
        try? await Task.sleep(for: .milliseconds(50))

        // Assert: the second, still in-flight playback's state must not be clobbered.
        XCTAssertTrue(viewModel.isPlaying)

        fake.finishPlayback(at: 0)
    }

    private func waitUntil(_ condition: @escaping () -> Bool, timeout: TimeInterval = 1.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }
}

private enum ChordPlaybackTestError: Error, LocalizedError {
    case engineUnavailable

    var errorDescription: String? { "boom" }
}

/// `stop()` deliberately does NOT resume a pending `play()` call — tests control exactly when
/// each in-flight call finishes via `finishPlayback(at:)`, indexed by call order. This is what
/// lets `test_aStalePlaybackTaskDoesNotOverwriteANewerOnesState` simulate a stopped playback
/// finishing late, after a newer one has already started.
private final class FakeChordSequencePlayer: ChordSequencePlaying, @unchecked Sendable {
    private struct State {
        var playedChordSequences: [[Chord]] = []
        var stopCallCount = 0
        var errorToThrow: Error?
        var continuations: [CheckedContinuation<Void, Error>] = []
    }

    private let state = LockedBox(State())

    var playedChordSequences: [[Chord]] { state.value.playedChordSequences }
    var stopCallCount: Int { state.value.stopCallCount }
    var errorToThrow: Error? {
        get { state.value.errorToThrow }
        set { state.withValue { $0.errorToThrow = newValue } }
    }

    func play(_ chords: [Chord]) async throws {
        let errorToThrow = state.withValue { state -> Error? in
            state.playedChordSequences.append(chords)
            return state.errorToThrow
        }
        if let errorToThrow {
            throw errorToThrow
        }
        try await withCheckedThrowingContinuation { continuation in
            state.withValue { $0.continuations.append(continuation) }
        }
    }

    func stop() {
        state.withValue { $0.stopCallCount += 1 }
    }

    func finishPlayback(at index: Int = 0) {
        let continuation = state.withValue { state -> CheckedContinuation<Void, Error>? in
            guard state.continuations.indices.contains(index) else { return nil }
            return state.continuations.remove(at: index)
        }
        continuation?.resume()
    }
}
