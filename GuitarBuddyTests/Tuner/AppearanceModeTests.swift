import SwiftUI
import XCTest
@testable import GuitarBuddy

final class AppearanceModeTests: XCTestCase {
    func test_systemFollowsDeviceColorScheme() {
        XCTAssertNil(AppearanceMode.system.colorScheme)
    }

    func test_lightAndDarkForceTheirSchemes() {
        XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
    }

    func test_everyModeHasTitleAndIcon() {
        for mode in AppearanceMode.allCases {
            XCTAssertFalse(mode.title.isEmpty)
            XCTAssertFalse(mode.systemImage.isEmpty)
        }
    }

    func test_rawValuesRoundTrip() {
        for mode in AppearanceMode.allCases {
            XCTAssertEqual(AppearanceMode(rawValue: mode.rawValue), mode)
        }
    }
}
