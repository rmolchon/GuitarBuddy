import XCTest
@testable import GuitarBuddy

/// End-to-end DSP checks against guitar/voice-like synthetic signals (see `SyntheticInstrument`)
/// rather than pure sines, so regressions in octave-error resistance, chord leakage or
/// segmentation show up without needing recorded audio.
final class SyntheticInstrumentDSPTests: XCTestCase {
    private let sampleRate = SyntheticInstrument.sampleRate
    private let detector = PitchDetector()

    // MARK: - Open strings

    func test_everyStandardTuningStringIsDetectedWithinFiveCentsOnEveryFrame() {
        for frequency in Tuning.standard.stringFrequencies {
            let signal = SyntheticInstrument.note(frequency: frequency, duration: 0.5, timbre: .forFrequency(frequency))
            for (index, frame) in SyntheticInstrument.frames(of: signal).enumerated() {
                let detected = detector.detectPitch(from: frame, sampleRate: sampleRate)
                XCTAssertNotNil(detected, "string \(frequency) Hz frame \(index) not detected")
                guard let detected else { continue }
                XCTAssertEqual(
                    SyntheticInstrument.cents(from: frequency, to: detected), 0, accuracy: 5,
                    "string \(frequency) Hz frame \(index) read \(detected) Hz"
                )
            }
        }
    }

    func test_stringsAreStillDetectedUnderBackgroundNoise() {
        for frequency in Tuning.standard.stringFrequencies {
            let clean = SyntheticInstrument.note(frequency: frequency, duration: 0.5, timbre: .forFrequency(frequency))
            let noisy = SyntheticInstrument.addingNoise(to: clean, amplitude: 0.02)
            let frame = SyntheticInstrument.frames(of: noisy)[0]
            let detected = detector.detectPitch(from: frame, sampleRate: sampleRate)
            XCTAssertNotNil(detected, "string \(frequency) Hz lost in noise")
            XCTAssertEqual(SyntheticInstrument.cents(from: frequency, to: detected ?? 0), 0, accuracy: 10)
        }
    }

    func test_detunedStringReportsItsOffset() {
        let flat = 110.0 * pow(2, -20.0 / 1200)
        let signal = SyntheticInstrument.note(frequency: flat, duration: 0.5, timbre: .woundString)
        let detected = detector.detectPitch(from: SyntheticInstrument.frames(of: signal)[0], sampleRate: sampleRate)
        XCTAssertEqual(SyntheticInstrument.cents(from: 110.0, to: detected ?? 0), -20, accuracy: 3)
    }

    func test_ringOutToSilenceEventuallyReturnsNil() {
        let signal = SyntheticInstrument.note(frequency: 110, duration: 0.3, timbre: .woundString)
            + SyntheticInstrument.silence(duration: 0.5)
        let frames = SyntheticInstrument.frames(of: signal)
        XCTAssertNil(detector.detectPitch(from: frames[frames.count - 1], sampleRate: sampleRate))
    }

    // MARK: - Chords

    private struct OpenChord {
        let name: String
        let frequencies: [Double]
        let expected: Chord
    }

    private let unseenChords = [
        OpenChord(name: "F barre", frequencies: [87.31, 130.81, 174.61, 220.00, 261.63, 349.23], expected: Chord(root: .f, quality: .major)),
        OpenChord(name: "D minor", frequencies: [146.83, 220.00, 293.66, 349.23], expected: Chord(root: .d, quality: .minor)),
        OpenChord(name: "B minor barre", frequencies: [123.47, 185.00, 246.94, 293.66, 369.99], expected: Chord(root: .b, quality: .minor)),
        OpenChord(name: "G7", frequencies: [98.00, 123.47, 146.83, 196.00, 246.94, 349.23], expected: Chord(root: .g, quality: .dominant7)),
        OpenChord(name: "Dsus4", frequencies: [146.83, 220.00, 293.66, 392.00], expected: Chord(root: .d, quality: .sus4)),
        OpenChord(name: "Fmaj7", frequencies: [130.81, 174.61, 220.00, 261.63, 329.63], expected: Chord(root: .f, quality: .major7))
    ]

    private let openChords = [
        OpenChord(name: "E major", frequencies: [82.41, 123.47, 164.81, 207.65, 246.94, 329.63], expected: Chord(root: .e, quality: .major)),
        OpenChord(name: "A minor", frequencies: [110.00, 164.81, 220.00, 261.63, 329.63], expected: Chord(root: .a, quality: .minor)),
        OpenChord(name: "C major", frequencies: [130.81, 164.81, 196.00, 261.63, 329.63], expected: Chord(root: .c, quality: .major)),
        OpenChord(name: "G major", frequencies: [98.00, 123.47, 146.83, 196.00, 246.94, 392.00], expected: Chord(root: .g, quality: .major)),
        OpenChord(name: "D major", frequencies: [146.83, 220.00, 293.66, 369.99], expected: Chord(root: .d, quality: .major)),
        OpenChord(name: "A major", frequencies: [110.00, 164.81, 220.00, 277.18, 329.63], expected: Chord(root: .a, quality: .major)),
        OpenChord(name: "E minor", frequencies: [82.41, 123.47, 164.81, 196.00, 246.94, 329.63], expected: Chord(root: .e, quality: .minor))
    ]

    func test_openChordStrumsAreRecognizedOnSustainedFrames() {
        assertRecognized(openChords, wound: .woundString, plain: .plainString)
    }

    /// A different timbre and unseen voicings are held to a recognition *rate*, not perfection:
    /// remaining misses are overtone phantoms on F-shaped chords (C3's 3rd harmonic is G, A3's is E),
    /// which a per-frame chroma can't fully separate from played notes. The segmenter's debounce
    /// absorbs isolated bad frames; this guards against regressing the overall rate.
    private let minimumRecognitionRate = 0.8

    func test_chordsAreMostlyRecognizedWithABrighterFasterDecayingTimbre() {
        let rate = recognitionRate(openChords, wound: .brightWoundString, plain: .brightPlainString)
        XCTAssertGreaterThanOrEqual(rate, minimumRecognitionRate)
    }

    func test_unseenVoicingsAreMostlyRecognized() {
        let standard = recognitionRate(unseenChords, wound: .woundString, plain: .plainString)
        let bright = recognitionRate(unseenChords, wound: .brightWoundString, plain: .brightPlainString)
        XCTAssertGreaterThanOrEqual(standard, minimumRecognitionRate)
        XCTAssertGreaterThanOrEqual(bright, minimumRecognitionRate)
    }

    private func sustainedPitchClassFrames(
        for chord: OpenChord,
        wound: SyntheticInstrument.Timbre,
        plain: SyntheticInstrument.Timbre
    ) -> [Set<PitchClass>] {
        let signal = SyntheticInstrument.strum(frequencies: chord.frequencies, duration: 0.7, wound: wound, plain: plain)
        // Skip frame 0: the strum is still being plucked string by string.
        return SyntheticInstrument.frames(of: signal).dropFirst().map {
            ChromaExtractor.activePitchClasses(from: $0, sampleRate: sampleRate)
        }
    }

    private func assertRecognized(_ chords: [OpenChord], wound: SyntheticInstrument.Timbre, plain: SyntheticInstrument.Timbre) {
        for chord in chords {
            for (index, pitchClasses) in sustainedPitchClassFrames(for: chord, wound: wound, plain: plain).enumerated() {
                XCTAssertEqual(
                    ChordRecognizer.recognizeChord(from: pitchClasses), chord.expected,
                    "\(chord.name) sustained frame \(index) heard as \(pitchClasses.map(\.displayName).sorted())"
                )
            }
        }
    }

    private func recognitionRate(_ chords: [OpenChord], wound: SyntheticInstrument.Timbre, plain: SyntheticInstrument.Timbre) -> Double {
        let results = chords.flatMap { chord in
            sustainedPitchClassFrames(for: chord, wound: wound, plain: plain).map {
                ChordRecognizer.recognizeChord(from: $0) == chord.expected
            }
        }
        return Double(results.filter { $0 }.count) / Double(max(1, results.count))
    }

    func test_strumProgressionProducesOneEventPerChordChange() {
        let segmenter = StrumSegmenter()
        let progression = ["C major", "G major", "A minor"]
        var events: [TranscriptionEvent] = []
        for name in progression {
            guard let chord = openChords.first(where: { $0.name == name }) else { return XCTFail("missing \(name)") }
            let signal = SyntheticInstrument.strum(frequencies: chord.frequencies, duration: 0.6)
                + SyntheticInstrument.silence(duration: 0.3)
            for frame in SyntheticInstrument.frames(of: signal) {
                let pitchClasses = ChromaExtractor.activePitchClasses(from: frame, sampleRate: sampleRate)
                if let event = segmenter.process(activePitchClasses: pitchClasses) { events.append(event) }
            }
        }
        XCTAssertEqual(events, [
            .chord(Chord(root: .c, quality: .major)),
            .chord(Chord(root: .g, quality: .major)),
            .chord(Chord(root: .a, quality: .minor))
        ])
    }

    // MARK: - Humming

    private struct HummedNote {
        let pitchClass: PitchClass
        let octave: Int
        let frequency: Double
    }

    func test_hummedMelodyWithVibratoIsTranscribedNoteForNote() {
        let melody = [
            HummedNote(pitchClass: .c, octave: 4, frequency: 261.63),
            HummedNote(pitchClass: .e, octave: 4, frequency: 329.63),
            HummedNote(pitchClass: .g, octave: 4, frequency: 392.00),
            HummedNote(pitchClass: .e, octave: 4, frequency: 329.63)
        ]
        let segmenter = HumNoteSegmenter()
        var notes: [DetectedNote] = []
        for hummed in melody {
            let signal = SyntheticInstrument.note(
                frequency: hummed.frequency, duration: 0.5, timbre: .voice, vibratoCents: 20, amplitude: 0.4
            ) + SyntheticInstrument.silence(duration: 0.2)
            for frame in SyntheticInstrument.frames(of: signal) {
                let pitch = detector.detectPitch(from: frame, sampleRate: sampleRate)
                if case .note(let note)? = segmenter.process(frequency: pitch) { notes.append(note) }
            }
        }
        XCTAssertEqual(notes.map(\.pitchClass), melody.map(\.pitchClass))
        XCTAssertEqual(notes.map(\.octave), melody.map(\.octave))
    }
}
