import Foundation

/// A value-type snapshot of one captured audio buffer, safe to hand to async consumers.
///
/// The `AVAudioPCMBuffer` a tap delivers is only valid for the duration of that tap
/// callback — reading it later (as an async `for await` consumer would) is a
/// use-after-free. `AudioEngineController` copies the samples out synchronously inside
/// the tap and publishes this instead.
struct AudioFrame: Sendable, Equatable {
    let samples: [Float]
    let sampleRate: Double
}
