protocol PitchDetecting: Sendable {
    func detectPitch(from samples: [Float], sampleRate: Double) -> Double?
}
