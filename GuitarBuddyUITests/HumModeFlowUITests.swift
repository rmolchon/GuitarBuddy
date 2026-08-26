import XCTest

final class HumModeFlowUITests: XCTestCase {
    private func openHumMode(_ app: XCUIApplication) {
        app.launch()
        app.tabBars.buttons["Hum Mode"].tap()
    }

    func test_humModeTabShowsListenButton() {
        // Arrange
        let app = XCUIApplication()
        // Act
        openHumMode(app)
        // Assert
        XCTAssertTrue(app.navigationBars["Hum Mode"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["humListenButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["humListenButton"].label, "Start Humming")
    }

    func test_tappingListenButtonTogglesItsLabel() {
        let app = XCUIApplication()
        openHumMode(app)

        let listenButton = app.buttons["humListenButton"]
        XCTAssertTrue(listenButton.waitForExistence(timeout: 5))
        listenButton.tap()

        XCTAssertEqual(listenButton.label, "Stop")

        listenButton.tap()
        XCTAssertEqual(listenButton.label, "Start Humming")
    }

    func test_navigatingAwayAndBackPreservesHumModeTab() {
        let app = XCUIApplication()
        openHumMode(app)

        app.tabBars.buttons["Tuner"].tap()
        XCTAssertTrue(app.navigationBars["Tuner"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Hum Mode"].tap()
        XCTAssertTrue(app.navigationBars["Hum Mode"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["humListenButton"].waitForExistence(timeout: 5))
    }
}
