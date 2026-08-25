import Foundation

struct Chord: Equatable {
    let root: PitchClass
    let quality: ChordQuality

    var displayName: String {
        "\(root.displayName)\(quality.displaySuffix)"
    }

    static func parse(_ symbol: String) -> Chord? {
        let normalized = symbol
            .replacingOccurrences(of: "\u{266F}", with: "#")
            .replacingOccurrences(of: "\u{266D}", with: "b")
            .trimmingCharacters(in: .whitespaces)

        guard let firstCharacter = normalized.first,
              let basePitch = PitchClass.fromLetter(Character(firstCharacter.uppercased()))
        else {
            return nil
        }

        let characters = Array(normalized)
        var suffixStartIndex = 1
        var semitoneShift = 0
        if characters.count > 1 {
            switch characters[1] {
            case "#":
                semitoneShift = 1
                suffixStartIndex = 2
            case "b":
                semitoneShift = -1
                suffixStartIndex = 2
            default:
                break
            }
        }

        let suffix = String(characters[suffixStartIndex...])
        guard let quality = ChordQuality.parse(suffix) else { return nil }

        return Chord(root: basePitch.applying(semitones: semitoneShift), quality: quality)
    }
}
