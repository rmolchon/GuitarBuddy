struct DiatonicSlot: Equatable {
    let root: PitchClass
    let family: QualityFamily
}

enum KeySignatureTable {
    private static let scaleDegreeSemitones = [0, 2, 4, 5, 7, 9, 11]
    private static let scaleDegreeFamilies: [QualityFamily] = [
        .majorFamily,
        .minorFamily,
        .minorFamily,
        .majorFamily,
        .majorFamily,
        .minorFamily,
        .diminishedFamily
    ]

    static func diatonicSlots(for tonic: PitchClass) -> [DiatonicSlot] {
        zip(scaleDegreeSemitones, scaleDegreeFamilies).map { semitones, family in
            DiatonicSlot(root: tonic.applying(semitones: semitones), family: family)
        }
    }
}
