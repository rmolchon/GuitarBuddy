import SwiftUI

struct TuningPickerView: View {
    @Binding var selectedTuning: Tuning

    var body: some View {
        Picker("Tuning", selection: $selectedTuning) {
            ForEach(Tuning.allPresets, id: \.self) { tuning in
                Text(tuning.name).tag(tuning)
            }
        }
        .pickerStyle(.menu)
        .accessibilityIdentifier("tuningPicker")
    }
}

#Preview {
    TuningPickerView(selectedTuning: .constant(.standard))
}
