import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @EnvironmentObject private var notifications: NotificationManager
    @State private var delivered: [UNNotification] = []

    var body: some View {
        List {
            if notifications.authorizationStatus != .authorized {
                Section {
                    Button("Attiva notifiche") { notifications.requestPermission() }
                } footer: {
                    Text("TripFlow potrà avvisarti per gate, ritardi e promemoria di viaggio.")
                }
            }

            Section("Test") {
                Button {
                    notifications.scheduleTestNotification()
                } label: {
                    Label("Invia notifica di prova", systemImage: "bell.badge.fill")
                }
                .disabled(notifications.authorizationStatus != .authorized)
            }

            Section("Ricevute") {
                if delivered.isEmpty {
                    ContentUnavailableView("Nessuna notifica", systemImage: "bell.slash", description: Text("Qui compariranno gli avvisi ricevuti."))
                } else {
                    ForEach(delivered, id: \.request.identifier) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.request.content.title).font(.headline)
                            Text(item.request.content.body).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Notifiche")
        .toolbar {
            if !delivered.isEmpty {
                Button("Segna lette") {
                    notifications.markAllRead()
                    delivered = []
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        delivered = await UNUserNotificationCenter.current().deliveredNotifications()
        notifications.unreadCount = delivered.count
    }
}
