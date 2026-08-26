import SwiftUI

struct RootTabView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        TabView {
            NavigationStack {
                TunerView()
                    .toolbar { appearanceToolbarItem }
            }
            .tabItem {
                Label("Tuner", systemImage: "tuningfork")
            }

            NavigationStack {
                KeyFinderView()
                    .toolbar { appearanceToolbarItem }
            }
            .tabItem {
                Label("Key Finder", systemImage: "music.quarternote.3")
            }

            NavigationStack {
                HumModeView()
                    .toolbar { appearanceToolbarItem }
            }
            .tabItem {
                Label("Hum Mode", systemImage: "waveform")
            }

            NavigationStack {
                ComingSoonView(feature: .transcribe)
                    .toolbar { appearanceToolbarItem }
            }
            .tabItem {
                Label(UpcomingFeature.transcribe.title, systemImage: UpcomingFeature.transcribe.systemImage)
            }
        }
    }

    @ToolbarContentBuilder
    private var appearanceToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Picker(selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                }
            } label: {
                Image(systemName: appearanceMode.systemImage)
            }
            .pickerStyle(.menu)
        }
    }
}

#Preview {
    RootTabView()
}
