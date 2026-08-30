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
            FlowLayout(spacing: 8) {
                ForEach(Array(chords.enumerated()), id: \.offset) { index, chord in
                    chip(for: chord, at: index)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func chip(for chord: Chord, at index: Int) -> some View {
        HStack(spacing: 4) {
            Text(chord.displayName)
                .font(.headline)
                .accessibilityIdentifier("chordChip_\(chord.displayName)")
            Button {
                onRemove(index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("removeChord_\(chord.displayName)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("chordChipContainer_\(chord.displayName)")
    }
}

#Preview {
    ChordSequenceView(chords: [Chord(root: .c, quality: .major), Chord(root: .a, quality: .minor)], onRemove: { _ in })
        .padding()
}
