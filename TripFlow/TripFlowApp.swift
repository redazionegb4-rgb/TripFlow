import SwiftUI

@main
struct TripFlowApp: App {
    @AppStorage("appearance") private var appearance = "system"
    @StateObject private var liveData = LiveDataStore()
    @StateObject private var notifications = NotificationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(liveData)
                .environmentObject(notifications)
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
