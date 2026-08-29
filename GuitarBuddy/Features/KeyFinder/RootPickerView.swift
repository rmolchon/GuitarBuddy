import SwiftUI

struct RootPickerView: View {
    @Binding var selectedRoot: PitchClass?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

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
        .accessibilityIdentifier("chordRootButton_\(pitch.displayName)")
    }
}

#Preview {
    RootPickerView(selectedRoot: .constant(.a))
        .padding()
}
