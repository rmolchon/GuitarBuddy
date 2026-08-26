import SwiftUI

struct HumNoteHistoryView: View {
    let notes: [DetectedNote]

    var body: some View {
        if notes.isEmpty {
            Text("Hum a melody to see the notes appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                        chip(for: note, at: index)
                    }
                }
            }
        }
    }

    private func chip(for note: DetectedNote, at index: Int) -> some View {
        Text("\(note.pitchClass.displayName)\(note.octave)")
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.15))
            .clipShape(Capsule())
            .accessibilityIdentifier("humNoteChip_\(index)")
    }
}

#Preview {
    HumNoteHistoryView(notes: [
        DetectedNote(pitchClass: .c, octave: 4, cents: 0),
        DetectedNote(pitchClass: .e, octave: 4, cents: 0),
        DetectedNote(pitchClass: .g, octave: 4, cents: 0)
    ])
    .padding()
}
