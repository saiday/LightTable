import SwiftUI

@main
struct LightTableApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .defaultSize(width: 800, height: 900)
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unified)
    }
}
