import SwiftUI

struct RootPickerView: View {
    @Binding var selectedRoot: PitchClass?

    // Adaptive so larger Dynamic Type sizes drop to fewer columns instead of truncating.
    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(PitchClass.allCases, id: \.self) { pitch in
                rootButton(for: pitch)
            }
        }
    }

    private func rootButton(for pitch: PitchClass) -> some View {
        let isSelected = selectedRoot == pitch
        return Button {
            selectedRoot = pitch
        } label: {
            Text(pitch.displayName)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : .secondary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("chordRootButton_\(pitch.displayName)")
    }
}

#Preview {
    RootPickerView(selectedRoot: .constant(.a))
        .padding()
}
