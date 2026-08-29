import SwiftUI

struct ChordPickerView: View {
    @Binding var selectedRoot: PitchClass?
    @Binding var selectedQuality: ChordQuality
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RootPickerView(selectedRoot: $selectedRoot)
            QualityPickerView(selectedQuality: $selectedQuality)

            HStack {
                if let selectedRoot {
                    Text(Chord(root: selectedRoot, quality: selectedQuality).displayName)
                        .font(.headline)
                        .accessibilityIdentifier("chordPreviewLabel")
                } else {
                    Text("Select a root note")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Add", action: onAdd)
                    .disabled(selectedRoot == nil)
                    .accessibilityIdentifier("addChordButton")
            }
        }
    }
}

#Preview {
    ChordPickerView(selectedRoot: .constant(.a), selectedQuality: .constant(.minor), onAdd: {})
        .padding()
}
