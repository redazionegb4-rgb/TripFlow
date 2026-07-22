import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack { FlightsView() }
                .tabItem { Label("Voli", systemImage: "airplane") }

            NavigationStack { PackingView() }
                .tabItem { Label("Valigia", systemImage: "suitcase.fill") }

            NavigationStack { DocumentsView() }
                .tabItem { Label("Documenti", systemImage: "doc.text.fill") }

            NavigationStack { SettingsView() }
                .tabItem { Label("Impostazioni", systemImage: "gearshape.fill") }
        }
        .tint(Color(red: 0.16, green: 0.64, blue: 0.95))
    }
}
