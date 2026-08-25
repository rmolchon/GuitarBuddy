import SwiftUI

struct TunerView: View {
    @State private var viewModel = TunerViewModel()

    var body: some View {
        VStack(spacing: 24) {
            TuningPickerView(selectedTuning: $viewModel.selectedTuning)

            StringIndicatorView(tuning: viewModel.selectedTuning, closestStringIndex: viewModel.closestStringIndex)

            VStack(spacing: 8) {
                Text(detectedNoteLabel)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())

                CentsMeterView(cents: viewModel.centsOffsetFromClosestString)
                    .padding(.horizontal, 32)
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
}

#Preview {
    NavigationStack {
        TunerView()
    }
}
