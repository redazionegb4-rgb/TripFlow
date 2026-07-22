import SwiftUI

@main
struct TripFlowApp: App {
    @AppStorage("appearance") private var appearance = "system"

    var body: some Scene {
        WindowGroup {
            RootView()
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
