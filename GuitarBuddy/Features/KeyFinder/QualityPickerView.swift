import SwiftUI

struct QualityPickerView: View {
    @Binding var selectedQuality: ChordQuality

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChordQuality.allCases, id: \.self) { quality in
                    qualityButton(for: quality)
                }
            }
        }
    }

    private func qualityButton(for quality: ChordQuality) -> some View {
        let isSelected = selectedQuality == quality
        return Button {
            selectedQuality = quality
        } label: {
            Text(Self.label(for: quality))
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : .secondary)
        .accessibilityIdentifier("chordQualityButton_\(Self.identifier(for: quality))")
    }

    private static func label(for quality: ChordQuality) -> String {
        switch quality {
        case .major: return "Major"
        case .minor: return "Minor"
        case .dominant7: return "7"
        case .major7: return "maj7"
        case .minor7: return "m7"
        case .diminished: return "dim"
        case .augmented: return "aug"
        case .sus2: return "sus2"
        case .sus4: return "sus4"
        }
    }

    private static func identifier(for quality: ChordQuality) -> String {
        switch quality {
        case .major: return "major"
        case .minor: return "minor"
        case .dominant7: return "dominant7"
        case .major7: return "major7"
        case .minor7: return "minor7"
        case .diminished: return "diminished"
        case .augmented: return "augmented"
        case .sus2: return "sus2"
        case .sus4: return "sus4"
        }
    }
}

#Preview {
    QualityPickerView(selectedQuality: .constant(.minor))
        .padding()
}
