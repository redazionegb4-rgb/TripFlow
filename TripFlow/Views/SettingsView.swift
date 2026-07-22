import SwiftUI

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("notifications") private var notifications = true
    @AppStorage("hour24") private var hour24 = true

    var body: some View {
        Form {
            Section("Aspetto") {
                Picker("Tema", selection: $appearance) {
                    Text("Automatico").tag("system")
                    Text("Chiaro").tag("light")
                    Text("Scuro").tag("dark")
                }
            }

            Section("Preferenze") {
                Toggle("Notifiche volo", isOn: $notifications)
                Toggle("Formato 24 ore", isOn: $hour24)
            }

            Section("Dati") {
                Label("Sincronizzazione iCloud", systemImage: "icloud.fill")
                Label("Privacy e sicurezza", systemImage: "lock.shield.fill")
            }

            Section("TripFlow") {
                LabeledContent("Versione", value: "1.0")
                LabeledContent("Build", value: "1")
            }
        }
        .navigationTitle("Impostazioni")
    }
}
