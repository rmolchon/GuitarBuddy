import AVFoundation
import os

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
///
/// Concurrency: `@unchecked Sendable` because the only non-`Sendable` stored property is the
/// `AVAudioEngine`, which is touched solely from `start()`/`performCleanup`. Every piece of
/// mutable state lives in `state`, which is only accessed through its lock.
final class AudioEngineController: @unchecked Sendable {
    /// `AsyncStream` defaults to unbounded buffering; for a live audio feed a backed-up
    /// consumer just wants the freshest frames, not a growing history. These caps give
    /// roughly a second of slack at the ~93 ms frame cadence before the oldest are dropped.
    private static let frameBufferDepth = 8
    private static let pitchBufferDepth = 16

    /// Tap buffer length in frames: ~93 ms at 44.1 kHz, enough for YIN to resolve low E (82 Hz).
    private static let tapBufferSize: AVAudioFrameCount = 4096

    private let engine: AVAudioEngine
    private let pitchDetector: PitchDetecting
    private let permissionProvider: RecordPermissionProviding
    private let frameContinuation: AsyncStream<AudioFrame>.Continuation
    private let pitchContinuation: AsyncStream<Double?>.Continuation

    /// Heavy DSP (YIN over 4096 samples) is dispatched here so it never blocks the
    /// real-time audio render thread the tap callback runs on.
    private let processingQueue = DispatchQueue(label: "com.guitarbuddy.audio.processing", qos: .userInitiated)

    /// All mutable controller state, guarded by `state`'s lock. `NSObjectProtocol` observer
    /// tokens aren't `Sendable`, hence `@unchecked` — they're only ever touched under the lock.
    private struct State: @unchecked Sendable {
        var isRunning = false
        var isStarting = false
        var tapInstalled = false
        var sessionActivated = false
        var observers: [NSObjectProtocol] = []
        var terminationError: AudioEngineControllerError?
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    /// What `performCleanup` must undo, captured atomically while resetting the state.
    private struct TeardownSnapshot {
        let hadTap: Bool
        let hadSession: Bool
        let observers: [NSObjectProtocol]
    }

    /// Non-nil once the session ended abnormally (failed `start()`, interruption, route
    /// loss, engine reconfiguration). A normal `stop()` leaves this nil.
    var terminationError: AudioEngineControllerError? {
        state.withLock { $0.terminationError }
    }

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

        (frameStream, frameContinuation) = AsyncStream.makeStream(
            of: AudioFrame.self,
            bufferingPolicy: .bufferingNewest(Self.frameBufferDepth)
        )
        (pitchStream, pitchContinuation) = AsyncStream.makeStream(
            of: Double?.self,
            bufferingPolicy: .bufferingNewest(Self.pitchBufferDepth)
        )

        registerDisruptionObservers()
    }

    deinit {
        performCleanup(dueTo: nil)
    }

    func start() async throws {
        try await requestRecordPermissionIfNeeded()

        // Single lock-guarded check-and-set so overlapping start() calls on the same
        // instance can't both reach installTap (a double tap install throws and crashes).
        let didClaimStart = state.withLock { state -> Bool in
            guard !state.isRunning, !state.isStarting else { return false }
            state.isStarting = true
            return true
        }
        guard didClaimStart else {
            AppLogger.audio.debug("start() ignored — engine already running or starting")
            return
        }
        defer { state.withLock { $0.isStarting = false } }

        // A prior stop()/disruption removes the observers; a fresh session needs them back.
        registerDisruptionObservers()

        do {
            try startEngine()
        } catch {
            let mapped = (error as? AudioEngineControllerError) ?? .invalidInputFormat
            performCleanup(dueTo: mapped)
            throw error
        }

        state.withLock {
            $0.isRunning = true
            $0.terminationError = nil
        }
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
        state.withLock { $0.sessionActivated = true }

        // Re-read the format *after* the session is active — on a real device the input
        // format isn't trustworthy until then, and installing a tap with a stale format
        // crashes with a hardware-format-mismatch assertion.
        let tapFormat = inputNode.outputFormat(forBus: 0)
        guard tapFormat.sampleRate > 0, tapFormat.channelCount > 0 else {
            AppLogger.audio.error("Invalid input format (post-activation): sampleRate=\(tapFormat.sampleRate), channelCount=\(tapFormat.channelCount)")
            throw AudioEngineControllerError.invalidInputFormat
        }

        engine.prepare()
        // `self` is `Sendable` (see the class doc), so the tap and queue closures capture it
        // weakly just to avoid a retain cycle through the engine's tap, not for thread safety.
        inputNode.installTap(onBus: 0, bufferSize: Self.tapBufferSize, format: tapFormat) { [weak self] buffer, _ in
            guard let self, let frame = Self.frame(from: buffer) else { return }
            self.processingQueue.async { [weak self] in
                self?.handle(frame)
            }
        }
        state.withLock { $0.tapInstalled = true }

        do {
            try engine.start()
        } catch {
            AppLogger.audio.error("AVAudioEngine failed to start: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private func performCleanup(dueTo error: AudioEngineControllerError?) {
        let snapshot = state.withLockUnchecked { state -> TeardownSnapshot in
            let snapshot = TeardownSnapshot(
                hadTap: state.tapInstalled,
                hadSession: state.sessionActivated,
                observers: state.observers
            )
            state.tapInstalled = false
            state.sessionActivated = false
            state.isRunning = false
            if let error {
                state.terminationError = error
            }
            state.observers = []
            return snapshot
        }
        let (hadTap, hadSession) = (snapshot.hadTap, snapshot.hadSession)

        for observer in snapshot.observers {
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
        let alreadyRegistered = state.withLock { !$0.observers.isEmpty }
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

        // Observer tokens aren't `Sendable`; they never leave the lock's critical section
        // except to be passed straight to `removeObserver` in `performCleanup`.
        state.withLockUnchecked { $0.observers = [interruption, routeChange, configChange] }
    }

    private func handleDisruption(_ reason: String) {
        // Observers live for as long as the controller does, so a disruption is honored
        // even between init and start(). Callers always create a fresh controller per
        // session (they never reuse one whose streams have finished), so a disruption in
        // that brief window just means the next start() gets a new instance.
        let alreadyTornDown = state.withLock { $0.observers.isEmpty }
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
