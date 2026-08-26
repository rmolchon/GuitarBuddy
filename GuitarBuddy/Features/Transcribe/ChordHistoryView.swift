import SwiftUI

struct ChordHistoryView: View {
    let chords: [Chord]

    var body: some View {
        if chords.isEmpty {
            Text("Strum a chord to see it appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(chords.enumerated()), id: \.offset) { index, chord in
                        chip(for: chord, at: index)
                    }
                }
            }
        }
    }

    private func chip(for chord: Chord, at index: Int) -> some View {
        Text(chord.displayName)
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.15))
            .clipShape(Capsule())
            .accessibilityIdentifier("transcribeChordChip_\(index)")
    }
}

#Preview {
    ChordHistoryView(chords: [
        Chord(root: .c, quality: .major),
        Chord(root: .a, quality: .minor),
        Chord(root: .f, quality: .major)
    ])
    .padding()
}
