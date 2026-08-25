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
        let input = app.textFields["chordInputField"]
        let addButton = app.buttons["addChordButton"]
        // Act
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText("C")
        addButton.tap()
        input.tap()
        input.typeText("Am")
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
        let input = app.textFields["chordInputField"]
        let addButton = app.buttons["addChordButton"]

        input.tap()
        input.typeText("G")
        addButton.tap()
        XCTAssertTrue(app.staticTexts["chordChip_G"].waitForExistence(timeout: 5))

        app.buttons["removeChord_G"].tap()
        XCTAssertFalse(app.staticTexts["chordChip_G"].waitForExistence(timeout: 2))
    }

    func test_invalidChordSymbolShowsAnErrorAndDoesNotAddAChip() {
        let app = XCUIApplication()
        openKeyFinder(app)
        let input = app.textFields["chordInputField"]
        let addButton = app.buttons["addChordButton"]

        input.tap()
        input.typeText("Zxyz")
        addButton.tap()

        XCTAssertTrue(app.staticTexts["invalidChordMessage"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["chordChip_Zxyz"].exists)
    }
}
