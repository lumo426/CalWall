import SwiftUI

@main
struct CalWallApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("CalWall", systemImage: "calendar") {
            ContentView()
                .environmentObject(appState)
                .task {
                    await appState.bootstrap()
                }
        }
        .menuBarExtraStyle(.window)
    }
}
