import SwiftUI

struct FlightsView: View {
    @State private var showingAddFlight = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                summary
                NavigationLink(destination: FlightDetailView(flight: .demo)) {
                    flightRow(.demo)
                }
                .buttonStyle(.plain)

                emptyPast
            }
            .padding(18)
        }
        .navigationTitle("I miei viaggi")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddFlight = true } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingAddFlight) { AddFlightView() }
    }

    private var summary: some View {
        HStack(spacing: 12) {
            stat("1", "In programma", "airplane.departure")
            stat("0", "Completati", "checkmark.circle")
        }
    }

    private func stat(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(AppTheme.accent)
            Text(value).font(.system(size: 28, weight: .bold, design: .rounded))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
    }

    private func flightRow(_ flight: Flight) -> some View {
        TravelCard {
            HStack {
                Text(flight.code).font(.subheadline.bold())
                Spacer()
                Text(flight.status.rawValue).font(.caption.bold()).foregroundStyle(.green)
            }
            HStack {
                Text(flight.originCode).font(.system(size: 28, weight: .black, design: .rounded))
                Spacer()
                Image(systemName: "airplane").foregroundStyle(AppTheme.accent)
                Spacer()
                Text(flight.destinationCode).font(.system(size: 28, weight: .black, design: .rounded))
            }
            Text(flight.departure.formatted(date: .long, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyPast: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Nessun viaggio passato")
                .font(.headline)
            Text("Qui troverai lo storico dei tuoi voli.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
    }
}

private struct AddFlightView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Volo") {
                    TextField("Numero volo, es. IB2627", text: $code)
                        .textInputAutocapitalization(.characters)
                    DatePicker("Data di partenza", selection: $date)
                }
                Section {
                    Text("In questa prima build il volo viene aggiunto manualmente. Nella versione con API basterà inserire numero e data per recuperare tutti i dati.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Aggiungi volo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Salva") { dismiss() }.disabled(code.isEmpty) }
            }
        }
    }
}
