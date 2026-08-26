import SwiftUI

struct TranscribeView: View {
    @State private var viewModel = TranscribeViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(viewModel.isListening ? .primary : .secondary)

            Button(viewModel.isListening ? "Stop" : "Start Strumming") {
                if viewModel.isListening {
                    viewModel.stop()
                } else {
                    viewModel.start()
                }
            }
            .accessibilityIdentifier("transcribeListenButton")

            ChordHistoryView(chords: viewModel.chords)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if !viewModel.chords.isEmpty {
                Button("Clear", role: .destructive, action: viewModel.clear)
                    .font(.footnote)
                    .accessibilityIdentifier("clearTranscribeChordsButton")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Transcribe")
        .onDisappear { viewModel.stop() }
    }
}

#Preview {
    NavigationStack {
        TranscribeView()
    }
}
