import XCTest

final class KeyFinderFlowUITests: XCTestCase {
    private func openKeyFinder(_ app: XCUIApplication) {
        app.launch()
        app.tabBars.buttons["Key Finder"].tap()
    }

    func test_addingChordsShowsChipsAndResolvesTheKey() {
        // Arrange
        let app = XCUIApplication()
        openKeyFinder(app)
        let addButton = app.buttons["addChordButton"]
        // Act
        XCTAssertTrue(app.buttons["chordRootButton_C"].waitForExistence(timeout: 5))
        app.buttons["chordRootButton_C"].tap()
        addButton.tap()

        app.buttons["chordRootButton_A"].tap()
        app.buttons["chordQualityButton_minor"].tap()
        addButton.tap()
        // Assert
        XCTAssertTrue(app.staticTexts["chordChip_C"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["chordChip_Am"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["keyResultHeadline"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["keyResultHeadline"].label, "C major")
    }

    func test_removingAChordChipUpdatesTheSequence() {
        let app = XCUIApplication()
        openKeyFinder(app)
        let addButton = app.buttons["addChordButton"]

        XCTAssertTrue(app.buttons["chordRootButton_G"].waitForExistence(timeout: 5))
        app.buttons["chordRootButton_G"].tap()
        addButton.tap()
        XCTAssertTrue(app.staticTexts["chordChip_G"].waitForExistence(timeout: 5))

        app.buttons["removeChord_G"].tap()
        XCTAssertFalse(app.staticTexts["chordChip_G"].waitForExistence(timeout: 2))
    }

    func test_lastChordChipStaysReachableWhenManyChordsAreAdded() {
        // Arrange
        let app = XCUIApplication()
        openKeyFinder(app)
        let addButton = app.buttons["addChordButton"]
        XCTAssertTrue(app.buttons["chordRootButton_C"].waitForExistence(timeout: 5))

        func add(root: String, quality: String? = nil) {
            app.buttons["chordRootButton_\(root)"].tap()
            if let quality { app.buttons["chordQualityButton_\(quality)"].tap() }
            addButton.tap()
        }

        // Act – add enough distinct chords to overflow a single on-screen row.
        for root in ["C", "D", "E", "F", "G", "A", "B"] { add(root: root) }
        for root in ["C", "D", "E", "F", "G"] { add(root: root, quality: "minor") }

        // Assert – the most recently added chip must remain visible and removable.
        let lastRemove = app.buttons["removeChord_Gm"]
        XCTAssertTrue(lastRemove.waitForExistence(timeout: 5))
        XCTAssertTrue(lastRemove.isHittable, "The newest chord chip should stay on-screen, not scrolled out of reach")
        lastRemove.tap()
        XCTAssertFalse(app.staticTexts["chordChip_Gm"].waitForExistence(timeout: 2))
    }

    func test_selectingAQualityAddsTheCorrespondingChordType() {
        let app = XCUIApplication()
        openKeyFinder(app)
        let addButton = app.buttons["addChordButton"]

        XCTAssertTrue(app.buttons["chordRootButton_G"].waitForExistence(timeout: 5))
        app.buttons["chordRootButton_G"].tap()
        app.buttons["chordQualityButton_dominant7"].tap()
        addButton.tap()

        XCTAssertTrue(app.staticTexts["chordChip_G7"].waitForExistence(timeout: 5))
    }

    func test_addButtonIsDisabledUntilARootIsSelected() {
        let app = XCUIApplication()
        openKeyFinder(app)

        XCTAssertTrue(app.buttons["addChordButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["addChordButton"].isEnabled)

        app.buttons["chordRootButton_D"].tap()
        XCTAssertTrue(app.buttons["addChordButton"].isEnabled)
    }

    func test_playButtonDisablesWhilePlayingAndReEnablesWhenPlaybackFinishes() {
        let app = XCUIApplication()
        openKeyFinder(app)

        XCTAssertTrue(app.buttons["chordRootButton_C"].waitForExistence(timeout: 5))
        app.buttons["chordRootButton_C"].tap()
        app.buttons["addChordButton"].tap()

        let playButton = app.buttons["playChordsButton"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        XCTAssertTrue(playButton.isEnabled)

        playButton.tap()
        XCTAssertFalse(playButton.isEnabled)

        let reenabled = NSPredicate(format: "isEnabled == true")
        expectation(for: reenabled, evaluatedWith: playButton)
        waitForExpectations(timeout: 10)
    }

    func test_clearingWhilePlayingStopsPlaybackImmediately() {
        let app = XCUIApplication()
        openKeyFinder(app)

        XCTAssertTrue(app.buttons["chordRootButton_C"].waitForExistence(timeout: 5))
        app.buttons["chordRootButton_C"].tap()
        app.buttons["addChordButton"].tap()
        app.buttons["playChordsButton"].tap()

        app.buttons["clearChordsButton"].tap()

        XCTAssertFalse(app.buttons["playChordsButton"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["chordChip_C"].exists)
    }
}
