import SwiftUI

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("notifications") private var notifications = true
    @AppStorage("hour24") private var hour24 = true
    @AppStorage("liveActivities") private var liveActivities = true

    var body: some View {
        List {
            Section {
                profileHeader
            }
            .listRowBackground(Color.clear)

            Section("Aspetto") {
                Picker("Tema", selection: $appearance) {
                    Text("Automatico").tag("system")
                    Text("Chiaro").tag("light")
                    Text("Scuro").tag("dark")
                }
                .pickerStyle(.navigationLink)
            }

            Section("Voli") {
                Toggle(isOn: $notifications) { settingLabel("Notifiche volo", "bell.badge.fill", .orange) }
                Toggle(isOn: $liveActivities) { settingLabel("Attività in tempo reale", "waveform.path.ecg.rectangle.fill", AppTheme.accent) }
                Toggle(isOn: $hour24) { settingLabel("Formato 24 ore", "clock.fill", .cyan) }
            }

            Section("Dati e sicurezza") {
                settingLabel("Sincronizzazione iCloud", "icloud.fill", .blue)
                settingLabel("Face ID per i documenti", "faceid", .green)
                settingLabel("Privacy", "hand.raised.fill", .pink)
            }

            Section("Informazioni") {
                LabeledContent("Versione", value: "1.0")
                Text("TripFlow è una build dimostrativa. Le API per voli, meteo e cambio verranno collegate dopo l'approvazione della grafica.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Impostazioni")
    }

    private var profileHeader: some View {
        HStack(spacing: 15) {
            ZStack {
                LinearGradient(colors: [AppTheme.accent, AppTheme.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "airplane")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(-35))
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 4) {
                Text("TripFlow").font(.title3.bold())
                Text("Assistente personale di viaggio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func settingLabel(_ title: String, _ icon: String, _ color: Color) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 26)
        }
    }
}
