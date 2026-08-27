import AVFoundation
@testable import GuitarBuddy

/// Deterministic stand-in for `SystemRecordPermissionProvider` — the real one hits live
/// system permission state, which is non-deterministic (and can hang awaiting a system
/// prompt) in a headless XCTest host.
struct FakeRecordPermissionProvider: RecordPermissionProviding {
    let recordPermission: AVAudioApplication.recordPermission
    let requestRecordPermissionResult: Bool

    init(
        recordPermission: AVAudioApplication.recordPermission = .granted,
        requestRecordPermissionResult: Bool = true
    ) {
        self.recordPermission = recordPermission
        self.requestRecordPermissionResult = requestRecordPermissionResult
    }

    func requestRecordPermission() async -> Bool {
        requestRecordPermissionResult
    }
}
