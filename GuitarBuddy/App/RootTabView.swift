import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TunerView()
            }
            .tabItem {
                Label("Tuner", systemImage: "tuningfork")
            }

            NavigationStack {
                ComingSoonView(feature: .keyFinder)
            }
            .tabItem {
                Label(UpcomingFeature.keyFinder.title, systemImage: UpcomingFeature.keyFinder.systemImage)
            }

            NavigationStack {
                ComingSoonView(feature: .humMode)
            }
            .tabItem {
                Label(UpcomingFeature.humMode.title, systemImage: UpcomingFeature.humMode.systemImage)
            }

            NavigationStack {
                ComingSoonView(feature: .transcribe)
            }
            .tabItem {
                Label(UpcomingFeature.transcribe.title, systemImage: UpcomingFeature.transcribe.systemImage)
            }
        }
    }
}

#Preview {
    RootTabView()
}
