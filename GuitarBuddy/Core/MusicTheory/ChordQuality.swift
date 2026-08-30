enum QualityFamily: Equatable {
    case majorFamily
    case minorFamily
    case diminishedFamily
}

enum ChordQuality: Equatable, CaseIterable {
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

    var displaySuffix: String {
        switch self {
        case .major: return ""
        case .minor: return "m"
        case .dominant7: return "7"
        case .minor7: return "m7"
        case .major7: return "maj7"
        case .diminished: return "dim"
        case .augmented: return "aug"
        case .sus2: return "sus2"
        case .sus4: return "sus4"
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

    /// Semitone offsets from the root for each chord tone.
    var intervals: [Int] {
        switch self {
        case .major: return [0, 4, 7]
        case .minor: return [0, 3, 7]
        case .dominant7: return [0, 4, 7, 10]
        case .major7: return [0, 4, 7, 11]
        case .minor7: return [0, 3, 7, 10]
        case .diminished: return [0, 3, 6]
        case .augmented: return [0, 4, 8]
        case .sus2: return [0, 2, 7]
        case .sus4: return [0, 5, 7]
        }
    }
}
