import SwiftUI

struct TunerView: View {
    @State private var viewModel = TunerViewModel()

    var body: some View {
        VStack(spacing: 24) {
            TuningPickerView(selectedTuning: $viewModel.selectedTuning)

            StringIndicatorView(tuning: viewModel.selectedTuning, closestStringIndex: viewModel.closestStringIndex)

            VStack(spacing: 8) {
                TunerGaugeView(
                    noteLabel: detectedNoteLabel,
                    previousNeighborLabel: neighborLabel(semitones: -1),
                    nextNeighborLabel: neighborLabel(semitones: 1),
                    cents: viewModel.centsOffsetFromClosestString
                )
                .padding(.horizontal, 16)

                Text(detectedNoteLabel)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(TunerGaugeView.tuningColor(forCents: viewModel.centsOffsetFromClosestString))
                    .contentTransition(.numericText())
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Tuner")
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var detectedNoteLabel: String {
        guard let note = viewModel.detectedNote else { return "—" }
        return "\(note.pitchClass.displayName)\(note.octave)"
    }

    private func neighborLabel(semitones: Int) -> String {
        guard let note = viewModel.detectedNote else { return "" }
        let neighbor = FrequencyToNote.neighborNote(pitchClass: note.pitchClass, octave: note.octave, semitones: semitones)
        return "\(neighbor.pitchClass.displayName)\(neighbor.octave)"
    }
}

#Preview {
    NavigationStack {
        TunerView()
    }
}
