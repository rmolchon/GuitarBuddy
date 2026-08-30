import AVFoundation
import Foundation

protocol ChordSequencePlaying {
    func play(_ chords: [Chord]) async throws
    func stop()
}

/// Thin AVAudioEngine wrapper around `ChordAudioSynthesizer`: builds one PCM buffer for the whole
/// chord sequence and schedules it on a single `AVAudioPlayerNode`, awaiting playback completion
/// so `KeyFinderViewModel` can drive a "Playing…" state from a single `await`.
///
/// `stop()` resumes the pending continuation itself rather than relying on
/// `AVAudioPlayerNode.stop()` to fire the buffer's completion handler — that behavior isn't
/// guaranteed, and an un-resumed `CheckedContinuation` would leak the playback task forever.
/// `continuationLock` guards against the natural completion handler and an explicit `stop()`
/// racing to resume the same continuation from different threads.
final class ChordSequencePlayer: ChordSequencePlaying {
    private let engine: AVAudioEngine
    private let playerNode: AVAudioPlayerNode
    private let format: AVAudioFormat
    private let continuationLock = NSLock()
    private var pendingContinuation: CheckedContinuation<Void, Never>?

    init(engine: AVAudioEngine = AVAudioEngine()) {
        self.engine = engine
        self.playerNode = AVAudioPlayerNode()
        self.format = AVAudioFormat(standardFormatWithSampleRate: ChordAudioSynthesizer.sampleRate, channels: 1)!
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
    }

    func play(_ chords: [Chord]) async throws {
        guard !chords.isEmpty else { return }
        guard let buffer = Self.buffer(from: ChordAudioSynthesizer.samples(for: chords), format: format) else { return }

        if !engine.isRunning {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            try engine.start()
        }

        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                continuationLock.lock()
                pendingContinuation = continuation
                continuationLock.unlock()

                playerNode.scheduleBuffer(buffer) { [weak self] in
                    self?.resumePendingContinuation()
                }
                playerNode.play()
            }
        } onCancel: { [weak self] in
            self?.stop()
        }
    }

    func stop() {
        playerNode.stop()
        resumePendingContinuation()
    }

    private func resumePendingContinuation() {
        continuationLock.lock()
        let continuation = pendingContinuation
        pendingContinuation = nil
        continuationLock.unlock()
        continuation?.resume()
    }

    private static func buffer(from samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channelData = buffer.floatChannelData
        else { return nil }

        buffer.frameLength = buffer.frameCapacity
        samples.withUnsafeBufferPointer { pointer in
            guard let baseAddress = pointer.baseAddress else { return }
            channelData[0].update(from: baseAddress, count: samples.count)
        }
        return buffer
    }
}
