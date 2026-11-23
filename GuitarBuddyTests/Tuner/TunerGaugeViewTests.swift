import SwiftUI
import XCTest
@testable import GuitarBuddy

@MainActor
final class TunerGaugeViewTests: XCTestCase {
    func test_noReadingIsSecondary() {
        XCTAssertEqual(TunerGaugeView.tuningColor(forCents: nil), .secondary)
    }

    func test_withinInTuneBandIsGreen() {
        XCTAssertEqual(TunerGaugeView.tuningColor(forCents: 4.9), .green)
        XCTAssertEqual(TunerGaugeView.tuningColor(forCents: -4.9), .green)
    }

    func test_betweenBandsIsOrange() {
        XCTAssertEqual(TunerGaugeView.tuningColor(forCents: TunerGaugeView.inTuneCents), .orange)
        XCTAssertEqual(TunerGaugeView.tuningColor(forCents: -19.9), .orange)
    }

    func test_farOffIsRed() {
        XCTAssertEqual(TunerGaugeView.tuningColor(forCents: TunerGaugeView.closeCents), .red)
        XCTAssertEqual(TunerGaugeView.tuningColor(forCents: -45), .red)
    }
}
