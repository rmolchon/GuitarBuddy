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

    func test_isInTuneOnlyInsideBand() {
        XCTAssertTrue(TunerGaugeView.isInTune(cents: 0))
        XCTAssertTrue(TunerGaugeView.isInTune(cents: -4.9))
        XCTAssertFalse(TunerGaugeView.isInTune(cents: 5))
        XCTAssertFalse(TunerGaugeView.isInTune(cents: nil))
    }

    func test_accessibilityDescriptionWithoutReading() {
        XCTAssertEqual(TunerGaugeView.accessibilityDescription(noteLabel: "—", cents: nil), "No note detected")
    }

    func test_accessibilityDescriptionInTune() {
        XCTAssertEqual(TunerGaugeView.accessibilityDescription(noteLabel: "A2", cents: 2), "A2, in tune")
    }

    func test_accessibilityDescriptionSharpAndFlat() {
        XCTAssertEqual(TunerGaugeView.accessibilityDescription(noteLabel: "A2", cents: 12.4), "A2, 12 cents sharp")
        XCTAssertEqual(TunerGaugeView.accessibilityDescription(noteLabel: "E2", cents: -30), "E2, 30 cents flat")
    }
}
