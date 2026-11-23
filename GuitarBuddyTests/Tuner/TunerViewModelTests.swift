import XCTest
@testable import GuitarBuddy

@MainActor
final class TunerViewModelTests: XCTestCase {
    /// A throwaway suite per test instance so persistence tests never touch real preferences.
    private let suiteName = "TunerViewModelTests-\(UUID().uuidString)"
    private lazy var defaults: UserDefaults = {
        let suite = UserDefaults(suiteName: suiteName) ?? .standard
        suite.removePersistentDomain(forName: suiteName)
        return suite
    }()

    private func makeViewModel() -> TunerViewModel {
        TunerViewModel(defaults: defaults)
    }

    // MARK: - Closest string / cents

    func test_noDetectionMeansNoClosestStringOrCents() {
        let viewModel = makeViewModel()
        XCTAssertNil(viewModel.closestStringIndex)
        XCTAssertNil(viewModel.centsOffsetFromClosestString)
        XCTAssertNil(viewModel.detectedNote)
    }

    func test_closestStringIsFoundForExactStandardTuningFrequency() {
        let viewModel = makeViewModel()
        viewModel.ingest(pitch: 110.0)
        XCTAssertEqual(viewModel.closestStringIndex, 1)
        XCTAssertEqual(viewModel.centsOffsetFromClosestString ?? .nan, 0, accuracy: 0.5)
    }

    func test_sharpReadingGivesPositiveCents() {
        let viewModel = makeViewModel()
        viewModel.ingest(pitch: 110.0 * pow(2, 10.0 / 1200.0))
        XCTAssertEqual(viewModel.centsOffsetFromClosestString ?? .nan, 10, accuracy: 0.5)
    }

    func test_flatReadingGivesNegativeCents() {
        let viewModel = makeViewModel()
        viewModel.ingest(pitch: 110.0 * pow(2, -10.0 / 1200.0))
        XCTAssertEqual(viewModel.centsOffsetFromClosestString ?? .nan, -10, accuracy: 0.5)
    }

    func test_closestStringFollowsSelectedTuning() {
        let viewModel = makeViewModel()
        viewModel.selectedTuning = .dropD
        viewModel.ingest(pitch: 73.42)
        XCTAssertEqual(viewModel.closestStringIndex, 0)
    }

    func test_nonStandardReferencePitchScalesTargets() {
        let viewModel = makeViewModel()
        viewModel.referencePitch = 432.0
        viewModel.ingest(pitch: 110.0 * 432.0 / 440.0)
        XCTAssertEqual(viewModel.closestStringIndex, 1)
        XCTAssertEqual(viewModel.centsOffsetFromClosestString ?? .nan, 0, accuracy: 0.5)
    }

    // MARK: - Smoothing

    func test_singleOutlierDoesNotMoveReadout() {
        let viewModel = makeViewModel()
        viewModel.ingest(pitch: 110.0)
        viewModel.ingest(pitch: 110.0)
        viewModel.ingest(pitch: 220.0)
        XCTAssertEqual(viewModel.lastDetectedFrequency ?? .nan, 110.0, accuracy: 0.001)
    }

    func test_briefDropoutKeepsReadout() {
        let viewModel = makeViewModel()
        viewModel.ingest(pitch: 110.0)
        viewModel.ingest(pitch: nil)
        XCTAssertEqual(viewModel.lastDetectedFrequency ?? .nan, 110.0, accuracy: 0.001)
    }

    func test_sustainedSilenceClearsReadout() {
        let viewModel = makeViewModel()
        viewModel.ingest(pitch: 110.0)
        for _ in 0..<(PitchSmoother.defaultHoldFrames + 1) {
            viewModel.ingest(pitch: nil)
        }
        XCTAssertNil(viewModel.lastDetectedFrequency)
    }

    // MARK: - Reference pitch persistence

    func test_referencePitchDefaultsToA440() {
        XCTAssertEqual(makeViewModel().referencePitch, 440.0)
    }

    func test_referencePitchPersistsAcrossInstances() {
        makeViewModel().referencePitch = 435.0
        XCTAssertEqual(makeViewModel().referencePitch, 435.0)
    }

    // MARK: - Lifecycle

    func test_stopClearsReadoutAndState() {
        let viewModel = makeViewModel()
        viewModel.ingest(pitch: 110.0)
        viewModel.stop()
        XCTAssertNil(viewModel.lastDetectedFrequency)
        XCTAssertFalse(viewModel.isListening)
        XCTAssertFalse(viewModel.isStarting)
    }

    func test_startFailureSurfacesErrorAndStaysIdle() async {
        let viewModel = TunerViewModel(
            defaults: defaults,
            makeAudioEngineController: {
                AudioEngineController(permissionProvider: FakeRecordPermissionProvider(recordPermission: .denied))
            }
        )
        viewModel.start()
        let deadline = ContinuousClock.now + .seconds(2)
        while viewModel.errorMessage == nil, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertEqual(viewModel.errorMessage, AudioEngineControllerError.permissionDenied.errorDescription)
        XCTAssertFalse(viewModel.isListening)
        XCTAssertFalse(viewModel.isStarting)
    }
}
