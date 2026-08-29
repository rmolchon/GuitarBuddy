import SwiftUI

struct KeyFinderView: View {
    @State private var viewModel = KeyFinderViewModel()

    var body: some View {
        VStack(spacing: 24) {
            ChordPickerView(
                selectedRoot: $viewModel.selectedRoot,
                selectedQuality: $viewModel.selectedQuality,
                onAdd: viewModel.addChord
            )

            ChordSequenceView(chords: viewModel.chords, onRemove: viewModel.removeChord)

            if !viewModel.chords.isEmpty {
                KeyResultView(result: viewModel.result)

                Button("Clear", role: .destructive, action: viewModel.clear)
                    .font(.footnote)
                    .accessibilityIdentifier("clearChordsButton")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Key Finder")
    }
}

#Preview {
    NavigationStack {
        KeyFinderView()
    }
}
