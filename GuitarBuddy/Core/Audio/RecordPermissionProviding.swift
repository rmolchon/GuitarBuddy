import AVFoundation

/// Abstracts `AVAudioApplication`'s microphone-permission API so `AudioEngineController`
/// is testable without touching the real system permission state — querying/requesting
/// it directly in a headless test host is non-deterministic (fresh permission state hangs
/// awaiting a system prompt that never appears).
protocol RecordPermissionProviding {
    var recordPermission: AVAudioApplication.recordPermission { get }
    func requestRecordPermission() async -> Bool
}

struct SystemRecordPermissionProvider: RecordPermissionProviding {
    var recordPermission: AVAudioApplication.recordPermission {
        AVAudioApplication.shared.recordPermission
    }

    func requestRecordPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }
}
