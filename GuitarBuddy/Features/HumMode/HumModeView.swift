import SwiftUI

struct HumModeView: View {
    @State private var viewModel = HumModeViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform")
                .font(.system(size: 48))
                .foregroundStyle(viewModel.isListening ? .primary : .secondary)

            Button(viewModel.isListening ? "Stop" : "Start Humming") {
                if viewModel.isListening {
                    viewModel.stop()
                } else {
                    viewModel.start()
                }
            }
            .accessibilityIdentifier("humListenButton")

            HumNoteHistoryView(notes: viewModel.notes)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            if !viewModel.notes.isEmpty {
                Button("Clear", role: .destructive, action: viewModel.clear)
                    .font(.footnote)
                    .accessibilityIdentifier("clearHumNotesButton")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Hum Mode")
        .onDisappear { viewModel.stop() }
    }
}

#Preview {
    NavigationStack {
        HumModeView()
    }
}
