import SwiftUI

@main
struct ChantDaubeApp: App {
    @StateObject private var alarm = AlarmStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarm)
        }
    }
}
