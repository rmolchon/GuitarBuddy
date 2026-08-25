import SwiftUI

struct CentsMeterView: View {
    let cents: Double?

    private let range: ClosedRange<Double> = -50...50

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(indicatorColor)
                    .frame(width: 4)
                    .offset(x: needleOffset(width: geometry.size.width))
            }
        }
        .frame(height: 12)
    }

    private var indicatorColor: Color {
        guard let cents else { return .secondary }
        switch abs(cents) {
        case ..<5: return .green
        case ..<20: return .yellow
        default: return .red
        }
    }

    private func needleOffset(width: CGFloat) -> CGFloat {
        guard let cents else { return width / 2 - 2 }
        let clamped = min(max(cents, range.lowerBound), range.upperBound)
        let fraction = (clamped - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(fraction) * (width - 4)
    }
}

#Preview {
    CentsMeterView(cents: 3)
        .padding()
}
