import SwiftUI

struct ChordSequenceView: View {
    let chords: [Chord]
    let onRemove: (Int) -> Void

    var body: some View {
        if chords.isEmpty {
            Text("Add chords to find the key")
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
        HStack(spacing: 4) {
            Text(chord.displayName)
                .font(.headline)
            Button {
                onRemove(index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.15))
        .clipShape(Capsule())
    }
}

#Preview {
    ChordSequenceView(chords: [Chord(root: .c, quality: .major), Chord(root: .a, quality: .minor)], onRemove: { _ in })
        .padding()
}
