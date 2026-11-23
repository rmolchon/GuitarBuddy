import SwiftUI

struct StringIndicatorView: View {
    let tuning: Tuning
    let closestStringIndex: Int?

    @ScaledMetric(relativeTo: .headline) private var circleSize: CGFloat = 36

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(tuning.stringFrequencies.enumerated()), id: \.offset) { index, frequency in
                Text(stringLabel(for: frequency))
                    .font(.headline)
                    .frame(width: circleSize, height: circleSize)
                    .background(index == closestStringIndex ? Color.accentColor : Color.clear)
                    .foregroundStyle(index == closestStringIndex ? Color.white : Color.primary)
                    .clipShape(Circle())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("String \(tuning.stringFrequencies.count - index), \(stringLabel(for: frequency))")
                    .accessibilityAddTraits(index == closestStringIndex ? .isSelected : [])
            }
        }
    }

    private func stringLabel(for frequency: Double) -> String {
        guard let note = FrequencyToNote.note(forFrequency: frequency) else { return "?" }
        return note.pitchClass.displayName
    }
}

#Preview {
    StringIndicatorView(tuning: .standard, closestStringIndex: 2)
}
