import SwiftUI

struct FlightsView: View {
    @State private var showAddFlight = false

    var body: some View {
        List {
            Section("Prossimo viaggio") {
                NavigationLink(destination: FlightDetailView(flight: .demo)) {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Text(Flight.demo.code).font(.headline)
                            Spacer()
                            Text(Flight.demo.status.rawValue)
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                        Text("\(Flight.demo.originCity) → \(Flight.demo.destinationCity)")
                            .font(.title3.bold())
                        Text(Flight.demo.departure.formatted(date: .long, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }

            Section {
                Button {
                    showAddFlight = true
                } label: {
                    Label("Aggiungi un volo", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("I miei voli")
        .sheet(isPresented: $showAddFlight) {
            AddFlightView()
        }
    }
}

struct AddFlightView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var flightCode = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Dati del volo") {
                    TextField("Numero volo, es. AZ610", text: $flightCode)
                        .textInputAutocapitalization(.characters)
                    DatePicker("Data", selection: $date, displayedComponents: .date)
                }
                Section {
                    Text("Nella prossima build il volo verrà cercato automaticamente tramite API.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Nuovo volo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Salva") { dismiss() }.disabled(flightCode.isEmpty) }
            }
        }
    }
}
