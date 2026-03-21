import SwiftUI

@main
struct LightTableApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 800, height: 900)
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unified)
    }
}
