import SwiftUI

struct ChordPickerView: View {
    @Binding var chordInput: String
    let invalidInputMessage: String?
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("Chord (e.g. C, Am, G7)", text: $chordInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .onSubmit(onAdd)

                Button("Add", action: onAdd)
                    .disabled(chordInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let invalidInputMessage {
                Text(invalidInputMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    ChordPickerView(chordInput: .constant("Am"), invalidInputMessage: nil, onAdd: {})
        .padding()
}
