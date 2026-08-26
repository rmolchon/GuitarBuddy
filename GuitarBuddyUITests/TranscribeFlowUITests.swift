import XCTest

final class TranscribeFlowUITests: XCTestCase {
    private func openTranscribe(_ app: XCUIApplication) {
        app.launch()
        app.tabBars.buttons["Transcribe"].tap()
    }

    func test_transcribeTabShowsListenButton() {
        // Arrange
        let app = XCUIApplication()
        // Act
        openTranscribe(app)
        // Assert
        XCTAssertTrue(app.navigationBars["Transcribe"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["transcribeListenButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["transcribeListenButton"].label, "Start Strumming")
    }

    func test_tappingListenButtonTogglesItsLabel() {
        let app = XCUIApplication()
        openTranscribe(app)

        let listenButton = app.buttons["transcribeListenButton"]
        XCTAssertTrue(listenButton.waitForExistence(timeout: 5))
        listenButton.tap()

        XCTAssertEqual(listenButton.label, "Stop")

        listenButton.tap()
        XCTAssertEqual(listenButton.label, "Start Strumming")
    }

    func test_navigatingAwayAndBackPreservesTranscribeTab() {
        let app = XCUIApplication()
        openTranscribe(app)

        app.tabBars.buttons["Tuner"].tap()
        XCTAssertTrue(app.navigationBars["Tuner"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Transcribe"].tap()
        XCTAssertTrue(app.navigationBars["Transcribe"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["transcribeListenButton"].waitForExistence(timeout: 5))
    }
}
