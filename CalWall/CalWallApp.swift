import SwiftUI

@main
struct CalWallApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("CalWall", systemImage: "calendar") {
            QuickScheduleView()
                .environmentObject(appState)
                .task {
                    await appState.bootstrap()
                }
        }
        .menuBarExtraStyle(.window)

        Window("CalWall Settings", id: "settings") {
            ContentView()
                .environmentObject(appState)
                .task {
                    await appState.bootstrap()
                }
        }
        .defaultSize(width: 500, height: 760)
        .windowResizability(.contentSize)
    }
}
