import SwiftUI

struct TranscribeView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 48
    @State private var viewModel = TranscribeViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note.list")
                .font(.system(size: iconSize))
                .accessibilityHidden(true)
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
        .onChange(of: viewModel.chords.count) { oldCount, newCount in
            guard newCount > oldCount, let latest = viewModel.chords.last else { return }
            AccessibilityNotification.Announcement(Self.announcement(for: latest)).post()
        }
    }
}

extension TranscribeView {
    static func announcement(for chord: Chord) -> String {
        "\(chord.displayName)"
    }
}

#Preview {
    NavigationStack {
        TranscribeView()
    }
}
