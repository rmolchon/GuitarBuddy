import AVFoundation

enum AudioEngineControllerError: LocalizedError {
    case invalidInputFormat
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .invalidInputFormat:
            return "Microphone input isn't available. Check that microphone access is allowed in Settings, then try again."
        case .permissionDenied:
            return "Microphone access is denied. Enable it for GuitarBuddy in Settings > Privacy & Security > Microphone."
        }
    }
}

final class AudioEngineController {
    private let engine: AVAudioEngine
    private let pitchDetector: PitchDetecting
    private let bufferContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation
    private let pitchContinuation: AsyncStream<Double?>.Continuation

    let bufferStream: AsyncStream<AVAudioPCMBuffer>
    let pitchStream: AsyncStream<Double?>

    init(engine: AVAudioEngine = AVAudioEngine(), pitchDetector: PitchDetecting = PitchDetector()) {
        self.engine = engine
        self.pitchDetector = pitchDetector

        var bufferContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation!
        bufferStream = AsyncStream { bufferContinuation = $0 }
        self.bufferContinuation = bufferContinuation

        var pitchContinuation: AsyncStream<Double?>.Continuation!
        pitchStream = AsyncStream { pitchContinuation = $0 }
        self.pitchContinuation = pitchContinuation
    }

    func start() async throws {
        try await requestRecordPermissionIfNeeded()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setActive(true)

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw AudioEngineControllerError.invalidInputFormat
        }
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            self?.handle(buffer)
        }
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        bufferContinuation.finish()
        pitchContinuation.finish()
    }

    private func requestRecordPermissionIfNeeded() async throws {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return
        case .denied:
            throw AudioEngineControllerError.permissionDenied
        case .undetermined:
            let granted = await AVAudioApplication.requestRecordPermission()
            guard granted else { throw AudioEngineControllerError.permissionDenied }
        @unknown default:
            throw AudioEngineControllerError.permissionDenied
        }
    }

    func handle(_ buffer: AVAudioPCMBuffer) {
        bufferContinuation.yield(buffer)
        let pitch = Self.samples(from: buffer).flatMap {
            pitchDetector.detectPitch(from: $0, sampleRate: buffer.format.sampleRate)
        }
        pitchContinuation.yield(pitch)
    }

    static func samples(from buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let channelData = buffer.floatChannelData, buffer.frameLength > 0 else { return nil }
        return Array(UnsafeBufferPointer(start: channelData[0], count: Int(buffer.frameLength)))
    }
}
