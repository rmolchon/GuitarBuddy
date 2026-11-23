import SwiftUI

struct HumModeView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 48
    @State private var viewModel = HumModeViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform")
                .font(.system(size: iconSize))
                .accessibilityHidden(true)
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
        .onChange(of: viewModel.notes.count) { oldCount, newCount in
            guard newCount > oldCount, let latest = viewModel.notes.last else { return }
            AccessibilityNotification.Announcement(Self.announcement(for: latest)).post()
        }
    }
}

extension HumModeView {
    static func announcement(for note: DetectedNote) -> String {
        "\(note.pitchClass.displayName)\(note.octave)"
    }
}

#Preview {
    NavigationStack {
        HumModeView()
    }
}
