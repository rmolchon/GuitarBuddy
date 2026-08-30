import AVFoundation

enum AudioEngineControllerError: LocalizedError, Equatable {
    case invalidInputFormat
    case permissionDenied
    case interrupted

    var errorDescription: String? {
        switch self {
        case .invalidInputFormat:
            return "Microphone input isn't available. Check that microphone access is allowed in Settings, then try again."
        case .permissionDenied:
            return "Microphone access is denied. Enable it for GuitarBuddy in Settings > Privacy & Security > Microphone."
        case .interrupted:
            return "Audio was interrupted (a call, another app, or a headset change). Tap Start to resume."
        }
    }
}

/// Owns a single `AVAudioEngine` mic-capture session and republishes it as two async
/// streams: `frameStream` (value-type sample snapshots) and `pitchStream` (YIN-detected Hz).
///
/// Reliability contract:
/// - `start()` is idempotent (a second call while running is a no-op) and transactional
///   (any failure fully unwinds the tap + session, exactly as `stop()` would).
/// - `stop()` is idempotent and safe to call before `start()` or twice.
/// - Pitch detection runs on `processingQueue`, never the real-time audio render thread.
/// - Interruptions / route changes / engine-config changes stop the session cleanly and
///   expose `terminationError` so consumers can surface it (no silent death).
final class AudioEngineController {
    /// `AsyncStream` defaults to unbounded buffering; for a live audio feed a backed-up
    /// consumer just wants the freshest frames, not a growing history. These caps give
    /// roughly a second of slack at the ~93 ms frame cadence before the oldest are dropped.
    private static let frameBufferDepth = 8
    private static let pitchBufferDepth = 16

    private let engine: AVAudioEngine
    private let pitchDetector: PitchDetecting
    private let permissionProvider: RecordPermissionProviding
    private let frameContinuation: AsyncStream<AudioFrame>.Continuation
    private let pitchContinuation: AsyncStream<Double?>.Continuation

    /// Heavy DSP (YIN over 4096 samples) is dispatched here so it never blocks the
    /// real-time audio render thread the tap callback runs on.
    private let processingQueue = DispatchQueue(label: "com.guitarbuddy.audio.processing", qos: .userInitiated)

    private let stateLock = NSLock()
    private var isRunning = false
    private var isStarting = false
    private var tapInstalled = false
    private var sessionActivated = false
    private var observers: [NSObjectProtocol] = []

    /// Non-nil once the session ended abnormally (failed `start()`, interruption, route
    /// loss, engine reconfiguration). A normal `stop()` leaves this nil.
    private(set) var terminationError: AudioEngineControllerError?

    let frameStream: AsyncStream<AudioFrame>
    let pitchStream: AsyncStream<Double?>

    init(
        engine: AVAudioEngine = AVAudioEngine(),
        pitchDetector: PitchDetecting = PitchDetector(),
        permissionProvider: RecordPermissionProviding = SystemRecordPermissionProvider()
    ) {
        self.engine = engine
        self.pitchDetector = pitchDetector
        self.permissionProvider = permissionProvider

        var frameContinuation: AsyncStream<AudioFrame>.Continuation!
        frameStream = AsyncStream(bufferingPolicy: .bufferingNewest(Self.frameBufferDepth)) { frameContinuation = $0 }
        self.frameContinuation = frameContinuation

        var pitchContinuation: AsyncStream<Double?>.Continuation!
        pitchStream = AsyncStream(bufferingPolicy: .bufferingNewest(Self.pitchBufferDepth)) { pitchContinuation = $0 }
        self.pitchContinuation = pitchContinuation

        registerDisruptionObservers()
    }

    deinit {
        performCleanup(dueTo: nil)
    }

    func start() async throws {
        try await requestRecordPermissionIfNeeded()

        // Single lock-guarded check-and-set so overlapping start() calls on the same
        // instance can't both reach installTap (a double tap install throws and crashes).
        stateLock.lock()
        guard !isRunning, !isStarting else {
            stateLock.unlock()
            AppLogger.audio.debug("start() ignored — engine already running or starting")
            return
        }
        isStarting = true
        stateLock.unlock()
        defer {
            stateLock.lock()
            isStarting = false
            stateLock.unlock()
        }

        // A prior stop()/disruption removes the observers; a fresh session needs them back.
        registerDisruptionObservers()

        do {
            try startEngine()
        } catch {
            let mapped = (error as? AudioEngineControllerError) ?? .invalidInputFormat
            performCleanup(dueTo: mapped)
            throw error
        }

        stateLock.lock()
        isRunning = true
        terminationError = nil
        stateLock.unlock()
        AppLogger.audio.debug("Audio engine started")
    }

    func stop() {
        performCleanup(dueTo: nil)
        AppLogger.audio.debug("Audio engine stopped")
    }

    // MARK: - Start / stop internals

    private func startEngine() throws {
        let inputNode = engine.inputNode

        // Cheap guard *before* touching AVAudioSession/engine.start(): reaching those with
        // no real input route (as in the XCTest host) SIGKILLs the process rather than
        // throwing, so this must short-circuit first.
        let preflightFormat = inputNode.outputFormat(forBus: 0)
        guard preflightFormat.sampleRate > 0, preflightFormat.channelCount > 0 else {
            AppLogger.audio.error("Invalid input format (preflight): sampleRate=\(preflightFormat.sampleRate), channelCount=\(preflightFormat.channelCount)")
            throw AudioEngineControllerError.invalidInputFormat
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try session.setActive(true)
        stateLock.lock()
        sessionActivated = true
        stateLock.unlock()

        // Re-read the format *after* the session is active — on a real device the input
        // format isn't trustworthy until then, and installing a tap with a stale format
        // crashes with a hardware-format-mismatch assertion.
        let tapFormat = inputNode.outputFormat(forBus: 0)
        guard tapFormat.sampleRate > 0, tapFormat.channelCount > 0 else {
            AppLogger.audio.error("Invalid input format (post-activation): sampleRate=\(tapFormat.sampleRate), channelCount=\(tapFormat.channelCount)")
            throw AudioEngineControllerError.invalidInputFormat
        }

        engine.prepare()
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: tapFormat) { [weak self] buffer, _ in
            guard let self, let frame = Self.frame(from: buffer) else { return }
            self.processingQueue.async { [weak self] in
                self?.handle(frame)
            }
        }
        stateLock.lock()
        tapInstalled = true
        stateLock.unlock()

        do {
            try engine.start()
        } catch {
            AppLogger.audio.error("AVAudioEngine failed to start: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private func performCleanup(dueTo error: AudioEngineControllerError?) {
        stateLock.lock()
        let hadTap = tapInstalled
        let hadSession = sessionActivated
        tapInstalled = false
        sessionActivated = false
        isRunning = false
        if let error {
            terminationError = error
        }
        let observersToRemove = observers
        observers = []
        stateLock.unlock()

        for observer in observersToRemove {
            NotificationCenter.default.removeObserver(observer)
        }
        if hadTap {
            engine.inputNode.removeTap(onBus: 0)
        }
        engine.stop()
        // Only deactivate the session if we activated it — otherwise a stale controller's
        // cleanup could yank the session out from under another feature (e.g. Key Finder
        // chord playback shares the process-wide AVAudioSession).
        if hadSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        frameContinuation.finish()
        pitchContinuation.finish()
    }

    // MARK: - Disruption handling (fail clean, surface an error)

    private func registerDisruptionObservers() {
        stateLock.lock()
        let alreadyRegistered = !observers.isEmpty
        stateLock.unlock()
        guard !alreadyRegistered else { return }

        let center = NotificationCenter.default
        let interruption = center.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: nil
        ) { [weak self] note in
            guard
                let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                AVAudioSession.InterruptionType(rawValue: raw) == .began
            else { return }
            self?.handleDisruption("audio session interruption began")
        }
        let routeChange = center.addObserver(
            forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil
        ) { [weak self] note in
            guard
                let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable
            else { return }
            self?.handleDisruption("input route became unavailable")
        }
        let configChange = center.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil
        ) { [weak self] _ in
            self?.handleDisruption("audio engine configuration changed")
        }

        stateLock.lock()
        observers = [interruption, routeChange, configChange]
        stateLock.unlock()
    }

    private func handleDisruption(_ reason: String) {
        // Observers live for as long as the controller does, so a disruption is honored
        // even between init and start(). Callers always create a fresh controller per
        // session (they never reuse one whose streams have finished), so a disruption in
        // that brief window just means the next start() gets a new instance.
        stateLock.lock()
        let alreadyTornDown = observers.isEmpty
        stateLock.unlock()
        guard !alreadyTornDown else { return }

        AppLogger.audio.warning("Audio session disrupted: \(reason, privacy: .public) — stopping engine")
        performCleanup(dueTo: .interrupted)
    }

    // MARK: - Permission

    private func requestRecordPermissionIfNeeded() async throws {
        switch permissionProvider.recordPermission {
        case .granted:
            AppLogger.audio.debug("Microphone permission granted")
            return
        case .denied:
            AppLogger.audio.warning("Microphone permission denied")
            throw AudioEngineControllerError.permissionDenied
        case .undetermined:
            let granted = await permissionProvider.requestRecordPermission()
            guard granted else {
                AppLogger.audio.warning("Microphone permission request declined")
                throw AudioEngineControllerError.permissionDenied
            }
        @unknown default:
            AppLogger.audio.warning("Microphone permission in unknown state")
            throw AudioEngineControllerError.permissionDenied
        }
    }

    // MARK: - Frame processing

    /// Synchronous processing seam (also the unit-test entry point). Invoked on
    /// `processingQueue`, never the audio render thread.
    func handle(_ frame: AudioFrame) {
        frameContinuation.yield(frame)
        let pitch = pitchDetector.detectPitch(from: frame.samples, sampleRate: frame.sampleRate)
        pitchContinuation.yield(pitch)
    }

    /// Copies a tap buffer into a value-type `AudioFrame` while the buffer is still valid.
    static func frame(from buffer: AVAudioPCMBuffer) -> AudioFrame? {
        guard let samples = samples(from: buffer) else { return nil }
        return AudioFrame(samples: samples, sampleRate: buffer.format.sampleRate)
    }

    static func samples(from buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let channelData = buffer.floatChannelData, buffer.frameLength > 0 else { return nil }
        return Array(UnsafeBufferPointer(start: channelData[0], count: Int(buffer.frameLength)))
    }
}
