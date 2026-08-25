import AVFoundation

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

    func start() throws {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            self?.handle(buffer)
        }
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        bufferContinuation.finish()
        pitchContinuation.finish()
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
