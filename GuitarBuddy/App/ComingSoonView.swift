import SwiftUI

enum UpcomingFeature {
    case humMode
    case transcribe

    var title: String {
        switch self {
        case .humMode: "Hum Mode"
        case .transcribe: "Transcribe"
        }
    }

    var systemImage: String {
        switch self {
        case .humMode: "waveform"
        case .transcribe: "music.note.list"
        }
    }
}

struct ComingSoonView: View {
    let feature: UpcomingFeature

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: feature.systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(feature.title)
                .font(.title2.bold())
            Text("Coming in a future update")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .navigationTitle(feature.title)
    }
}

#Preview {
    ComingSoonView(feature: .humMode)
}
