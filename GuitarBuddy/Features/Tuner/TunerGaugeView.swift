import SwiftUI

/// An analog-style tuner gauge: a needle sweeping across an arc between the detected
/// note's chromatic neighbors, with a colored band marking the in-tune zone.
struct TunerGaugeView: View {
    let noteLabel: String
    let previousNeighborLabel: String
    let nextNeighborLabel: String
    let cents: Double?

    private let centsRange: ClosedRange<Double> = -50...50
    private let sweepDegrees: Double = 65
    private let bandSweepDegrees: Double = 32
    private let greenThresholdCents: Double = 5
    private let orangeThresholdCents: Double = 20

    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width / 2, geometry.size.height - 24)
            let center = CGPoint(x: geometry.size.width / 2, y: radius)

            ZStack {
                guideArc(center: center, radius: radius)
                colorBand(center: center, radius: radius)
                neighborLabel(previousNeighborLabel, angle: -sweepDegrees, center: center, radius: radius)
                neighborLabel(nextNeighborLabel, angle: sweepDegrees, center: center, radius: radius)
                topLabel(center: center, radius: radius)
                needle(center: center, radius: radius)
                pivot(center: center)
            }
        }
        .frame(height: 160)
    }

    private func guideArc(center: CGPoint, radius: CGFloat) -> some View {
        arcPath(center: center, radius: radius, fromDegrees: -sweepDegrees, toDegrees: sweepDegrees)
            .stroke(Color.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    private func colorBand(center: CGPoint, radius: CGFloat) -> some View {
        let greenHalfSweep = bandSweepDegrees * (greenThresholdCents / centsRange.upperBound)
        return ZStack {
            arcPath(center: center, radius: radius, fromDegrees: -bandSweepDegrees, toDegrees: -greenHalfSweep)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 6, lineCap: .butt))
            arcPath(center: center, radius: radius, fromDegrees: greenHalfSweep, toDegrees: bandSweepDegrees)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 6, lineCap: .butt))
            arcPath(center: center, radius: radius, fromDegrees: -greenHalfSweep, toDegrees: greenHalfSweep)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .butt))
        }
    }

    private func arcPath(center: CGPoint, radius: CGFloat, fromDegrees: Double, toDegrees: Double) -> Path {
        Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: gaugeAngle(fromDegrees),
                endAngle: gaugeAngle(toDegrees),
                clockwise: false
            )
        }
    }

    private func neighborLabel(_ label: String, angle: Double, center: CGPoint, radius: CGFloat) -> some View {
        Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
            .position(point(angleDegrees: angle, radius: radius + 16, center: center))
    }

    private func topLabel(center: CGPoint, radius: CGFloat) -> some View {
        Text(noteLabel)
            .font(.headline)
            .foregroundStyle(needleColor)
            .position(point(angleDegrees: 0, radius: radius - 28, center: center))
    }

    private func needle(center: CGPoint, radius: CGFloat) -> some View {
        Path { path in
            path.move(to: center)
            path.addLine(to: point(angleDegrees: needleAngleDegrees, radius: radius - 10, center: center))
        }
        .stroke(needleColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .animation(.easeOut(duration: 0.15), value: needleAngleDegrees)
    }

    private func pivot(center: CGPoint) -> some View {
        Circle()
            .fill(needleColor)
            .frame(width: 14, height: 14)
            .position(center)
    }

    private var needleAngleDegrees: Double {
        guard let cents else { return 0 }
        let clamped = min(max(cents, centsRange.lowerBound), centsRange.upperBound)
        return (clamped / centsRange.upperBound) * sweepDegrees
    }

    private var needleColor: Color {
        Self.tuningColor(forCents: cents, greenThreshold: greenThresholdCents, orangeThreshold: orangeThresholdCents)
    }

    /// Maps a cents offset to the same green/orange/red tiers the gauge uses, so the big
    /// readout label below the gauge can match the needle's color.
    static func tuningColor(forCents cents: Double?, greenThreshold: Double = 5, orangeThreshold: Double = 20) -> Color {
        guard let cents else { return .secondary }
        switch abs(cents) {
        case ..<greenThreshold: return .green
        case ..<orangeThreshold: return .orange
        default: return .red
        }
    }

    /// Converts an angle measured clockwise from the gauge's vertical (12 o'clock = 0°)
    /// into SwiftUI's `Path.addArc` angle, which is measured from the 3 o'clock position.
    private func gaugeAngle(_ degreesFromVertical: Double) -> Angle {
        .degrees(degreesFromVertical - 90)
    }

    private func point(angleDegrees: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let radians = angleDegrees * .pi / 180
        return CGPoint(x: center.x + radius * sin(radians), y: center.y - radius * cos(radians))
    }
}

#Preview {
    VStack(spacing: 32) {
        TunerGaugeView(noteLabel: "A2", previousNeighborLabel: "G#2", nextNeighborLabel: "A#2", cents: 2)
        TunerGaugeView(noteLabel: "A2", previousNeighborLabel: "G#2", nextNeighborLabel: "A#2", cents: -35)
        TunerGaugeView(noteLabel: "—", previousNeighborLabel: "", nextNeighborLabel: "", cents: nil)
    }
    .padding()
}
