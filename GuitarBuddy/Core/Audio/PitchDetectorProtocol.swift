protocol PitchDetecting {
    func detectPitch(from samples: [Float], sampleRate: Double) -> Double?
}
