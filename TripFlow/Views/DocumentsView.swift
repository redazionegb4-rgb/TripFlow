import SwiftUI

struct DocumentsView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                securityBanner
                document("Passaporto", "Scade il 14 aprile 2031", "person.text.rectangle.fill", .indigo)
                document("Assicurazione viaggio", "Polizza New York", "shield.checkered", .green)
                document("Prenotazione hotel", "46 notti · Manhattan", "bed.double.fill", .orange)
                addButton
            }
            .padding(18)
        }
        .navigationTitle("Documenti")
    }

    private var securityBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "faceid")
                .font(.title2)
                .foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text("Protetti con Face ID").font(.headline)
                Text("I documenti restano salvati sul dispositivo.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(AppTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
    }

    private func document(_ title: String, _ subtitle: String, _ icon: String, _ color: Color) -> some View {
        TravelCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
        }
    }

    private var addButton: some View {
        Button(action: {}) {
            Label("Aggiungi documento", systemImage: "plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 18))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}
