import Foundation

struct DetectedNote: Equatable {
    let pitchClass: PitchClass
    let octave: Int
    let cents: Double
}

enum FrequencyToNote {
    private static let a4MidiNumber = 69

    static func note(forFrequency frequency: Double, referencePitch: Double = 440.0) -> DetectedNote? {
        guard frequency > 0 else { return nil }

        let semitonesFromA4 = 12 * log2(frequency / referencePitch)
        let roundedSemitones = semitonesFromA4.rounded()
        let cents = 100 * (semitonesFromA4 - roundedSemitones)

        let midiNumber = a4MidiNumber + Int(roundedSemitones)
        let pitchClassIndex = ((midiNumber % 12) + 12) % 12
        let octave = midiNumber / 12 - 1

        return DetectedNote(pitchClass: PitchClass(rawValue: pitchClassIndex)!, octave: octave, cents: cents)
    }

    static func frequency(forPitchClass pitchClass: PitchClass, octave: Int, referencePitch: Double = 440.0) -> Double {
        let midiNumber = (octave + 1) * 12 + pitchClass.rawValue
        let semitonesFromA4 = Double(midiNumber - a4MidiNumber)
        return referencePitch * pow(2, semitonesFromA4 / 12)
    }
}
