import XCTest
@testable import GuitarBuddy

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
}
