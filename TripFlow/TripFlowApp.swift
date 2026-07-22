import SwiftUI

@main
struct TripFlowApp: App {
    @AppStorage("appearance") private var appearance = "system"
    @StateObject private var liveData = LiveDataStore()
    @StateObject private var notifications = NotificationManager()
    @StateObject private var trips = TripStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(liveData)
                .environmentObject(notifications)
                .environmentObject(trips)
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        appearance == "light" ? .light : appearance == "dark" ? .dark : nil
    }
}
