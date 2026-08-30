import SwiftUI

struct KeyFinderView: View {
    @State private var viewModel = KeyFinderViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ChordPickerView(
                    selectedRoot: $viewModel.selectedRoot,
                    selectedQuality: $viewModel.selectedQuality,
                    onAdd: viewModel.addChord
                )

                ChordSequenceView(chords: viewModel.chords, onRemove: viewModel.removeChord)

                if !viewModel.chords.isEmpty {
                    KeyResultView(result: viewModel.result)

                    HStack(spacing: 16) {
                        Button(viewModel.isPlaying ? "Playing…" : "Play") {
                            viewModel.playChords()
                        }
                        .font(.footnote)
                        .disabled(viewModel.isPlaying)
                        .accessibilityIdentifier("playChordsButton")

                        Button("Clear", role: .destructive, action: viewModel.clear)
                            .font(.footnote)
                            .accessibilityIdentifier("clearChordsButton")
                    }

                    if let playbackErrorMessage = viewModel.playbackErrorMessage {
                        Text(playbackErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("playbackErrorMessage")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Key Finder")
        .onDisappear { viewModel.stopPlayback() }
    }
}

#Preview {
    NavigationStack {
        KeyFinderView()
    }
}
