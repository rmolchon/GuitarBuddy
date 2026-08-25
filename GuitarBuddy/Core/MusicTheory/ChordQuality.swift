enum QualityFamily: Equatable {
    case majorFamily
    case minorFamily
    case diminishedFamily
}

enum ChordQuality: Equatable {
    case major
    case minor
    case dominant7
    case major7
    case minor7
    case diminished
    case augmented
    case sus2
    case sus4

    static func parse(_ suffix: String) -> ChordQuality? {
        switch suffix {
        case "": return .major
        case "m": return .minor
        case "7": return .dominant7
        case "m7": return .minor7
        case "maj7": return .major7
        case "dim": return .diminished
        case "aug": return .augmented
        case "sus2": return .sus2
        case "sus4": return .sus4
        default: return nil
        }
    }

    var family: QualityFamily {
        switch self {
        case .major, .dominant7, .major7, .augmented, .sus2, .sus4:
            return .majorFamily
        case .minor, .minor7:
            return .minorFamily
        case .diminished:
            return .diminishedFamily
        }
    }
}
