import SwiftUI

struct RootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house") }
                .tag(0)

            NavigationStack { FlightsView() }
                .tabItem { Label("Viaggi", systemImage: selectedTab == 1 ? "airplane.circle.fill" : "airplane.circle") }
                .tag(1)

            NavigationStack { PackingView() }
                .tabItem { Label("Valigia", systemImage: selectedTab == 2 ? "suitcase.fill" : "suitcase") }
                .tag(2)

            NavigationStack { DocumentsView() }
                .tabItem { Label("Documenti", systemImage: selectedTab == 3 ? "doc.text.fill" : "doc.text") }
                .tag(3)

            NavigationStack { SettingsView() }
                .tabItem { Label("Impostazioni", systemImage: selectedTab == 4 ? "gearshape.fill" : "gearshape") }
                .tag(4)
        }
        .tint(AppTheme.accent)
    }
}

enum AppTheme {
    static let accent = Color(red: 0.29, green: 0.38, blue: 0.98)
    static let cyan = Color(red: 0.18, green: 0.79, blue: 0.86)
    static let navy = Color(red: 0.04, green: 0.07, blue: 0.15)
}
