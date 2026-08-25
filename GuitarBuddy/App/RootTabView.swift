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
                ComingSoonView(feature: .keyFinder)
                    .toolbar { appearanceToolbarItem }
            }
            .tabItem {
                Label(UpcomingFeature.keyFinder.title, systemImage: UpcomingFeature.keyFinder.systemImage)
            }

            NavigationStack {
                ComingSoonView(feature: .humMode)
                    .toolbar { appearanceToolbarItem }
            }
            .tabItem {
                Label(UpcomingFeature.humMode.title, systemImage: UpcomingFeature.humMode.systemImage)
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
