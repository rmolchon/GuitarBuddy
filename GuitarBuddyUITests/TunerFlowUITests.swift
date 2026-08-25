import XCTest

final class TunerFlowUITests: XCTestCase {
    func test_tunerTabIsSelectedByDefaultAndShowsStandardTuning() {
        // Arrange
        let app = XCUIApplication()
        // Act
        app.launch()
        // Assert
        XCTAssertTrue(app.navigationBars["Tuner"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tuningPicker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tuningPicker"].label.contains("Standard"))
    }

    func test_selectingAlternateTuningUpdatesThePickerLabel() {
        let app = XCUIApplication()
        app.launch()

        let picker = app.buttons["tuningPicker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()

        let dropD = app.buttons["Drop D"]
        XCTAssertTrue(dropD.waitForExistence(timeout: 5))
        dropD.tap()

        XCTAssertTrue(picker.label.contains("Drop D"))
    }

    func test_navigatingToKeyFinderTabAndBackPreservesTunerState() {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Key Finder"].tap()
        XCTAssertTrue(app.navigationBars["Key Finder"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Tuner"].tap()
        XCTAssertTrue(app.navigationBars["Tuner"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tuningPicker"].label.contains("Standard"))
    }
}
