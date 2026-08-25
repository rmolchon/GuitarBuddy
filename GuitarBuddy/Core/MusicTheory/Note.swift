enum PitchClass: Int, CaseIterable, Equatable {
    case c = 0
    case cSharp
    case d
    case dSharp
    case e
    case f
    case fSharp
    case g
    case gSharp
    case a
    case aSharp
    case b

    static func fromLetter(_ letter: Character) -> PitchClass? {
        switch letter {
        case "C": return .c
        case "D": return .d
        case "E": return .e
        case "F": return .f
        case "G": return .g
        case "A": return .a
        case "B": return .b
        default: return nil
        }
    }

    func applying(semitones: Int) -> PitchClass {
        let shifted = ((rawValue + semitones) % 12 + 12) % 12
        return PitchClass(rawValue: shifted)!
    }

    var displayName: String {
        switch self {
        case .c: return "C"
        case .cSharp: return "C#"
        case .d: return "D"
        case .dSharp: return "D#"
        case .e: return "E"
        case .f: return "F"
        case .fSharp: return "F#"
        case .g: return "G"
        case .gSharp: return "G#"
        case .a: return "A"
        case .aSharp: return "A#"
        case .b: return "B"
        }
    }
}
