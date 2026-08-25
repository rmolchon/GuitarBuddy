import SwiftUI

struct KeyResultView: View {
    let result: KeyMatchResult

    var body: some View {
        VStack(spacing: 8) {
            Text(headline)
                .font(.title.bold())
                .accessibilityIdentifier("keyResultHeadline")
            Text("\(Int(result.confidence * 100))% confidence")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var headline: String {
        guard let key = result.key, !result.isAmbiguous else { return "Ambiguous" }
        return key.name
    }
}

#Preview {
    KeyResultView(result: KeyMatchResult(key: MusicalKey(tonic: .c), confidence: 1.0, isAmbiguous: false))
}
