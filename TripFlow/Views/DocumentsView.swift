import SwiftUI

struct DocumentsView: View {
    var body: some View {
        List {
            Section {
                documentRow("Passaporto", "Valido fino al 14/08/2031", "person.text.rectangle.fill")
                documentRow("Assicurazione viaggio", "Da aggiungere", "cross.case.fill")
                documentRow("Prenotazione hotel", "Da aggiungere", "bed.double.fill")
                documentRow("Biglietti", "1 documento", "ticket.fill")
            }

            Section {
                Button { } label: {
                    Label("Aggiungi documento", systemImage: "plus.circle.fill")
                }
            }

            Section {
                Label("I documenti saranno protetti con Face ID e salvati solo sul dispositivo.", systemImage: "faceid")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Documenti")
    }

    private func documentRow(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 38, height: 38)
                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}
