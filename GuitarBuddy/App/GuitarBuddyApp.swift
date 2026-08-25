import SwiftUI

@main
struct GuitarBuddyApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(appearanceMode.colorScheme)
        }
    }
}
