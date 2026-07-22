import SwiftUI

struct FlightsView: View {
    @EnvironmentObject private var trips: TripStore
    @State private var showingAddFlight = false

    var body: some View {
        List {
            Section { summary }
            Section("Viaggi salvati") {
                if trips.flights.isEmpty {
                    ContentUnavailableView("Nessun viaggio", systemImage: "airplane", description: Text("Premi + per aggiungerne uno."))
                }
                ForEach(trips.flights) { flight in
                    NavigationLink(destination: FlightDetailView(flight: flight)) { flightRow(flight) }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { trips.delete(flight) } label: { Label("Elimina", systemImage: "trash") }
                        }
                        .contextMenu {
                            Button(role: .destructive) { trips.delete(flight) } label: { Label("Elimina viaggio", systemImage: "trash") }
                        }
                }
                .onDelete(perform: trips.delete)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("I miei viaggi")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button { showingAddFlight = true } label: { Image(systemName: "plus") } }
            ToolbarItem(placement: .topBarLeading) { EditButton() }
        }
        .sheet(isPresented: $showingAddFlight) { AddFlightView() }
    }

    private var summary: some View {
        HStack {
            stat("\(trips.flights.filter { $0.departure > Date() }.count)", "In programma")
            Divider()
            stat("\(trips.flights.filter { $0.departure <= Date() }.count)", "Completati")
        }.padding(.vertical, 8)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack { Text(value).font(.title.bold()); Text(label).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity)
    }

    private func flightRow(_ f: Flight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text(f.code).font(.headline); Spacer(); Text(f.status.rawValue).font(.caption.bold()).foregroundStyle(AppTheme.accent) }
            HStack { Text(f.originCode).font(.title2.bold()); Image(systemName: "arrow.right").foregroundStyle(.secondary); Text(f.destinationCode).font(.title2.bold()) }
            Text("\(f.originCity) → \(f.destinationCity)").font(.caption)
            Text(f.departure.formatted(date: .long, time: .shortened)).font(.caption).foregroundStyle(.secondary)
        }.padding(.vertical, 5)
    }
}

private struct AddFlightView: View {
    @EnvironmentObject private var trips: TripStore
    @EnvironmentObject private var liveData: LiveDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var selectedDate = Date().addingTimeInterval(86_400)
    @State private var airline = ""
    @State private var originCode = ""
    @State private var originCity = ""
    @State private var destinationCode = ""
    @State private var destinationCity = ""
    @State private var departure = Date().addingTimeInterval(86_400)
    @State private var arrival = Date().addingTimeInterval(90_000)
    @State private var terminal = "Da assegnare"
    @State private var gate = "Da assegnare"
    @State private var seat = ""
    @State private var isSearching = false
    @State private var searchCompleted = false
    @State private var errorText: String?

    private var valid: Bool { searchCompleted && !code.isEmpty && !originCode.isEmpty && !destinationCode.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trova automaticamente il volo") {
                    TextField("Numero volo, es. IB2627", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .onChange(of: code) { _, _ in searchCompleted = false }
                    DatePicker("Data del volo", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) { _, _ in searchCompleted = false }
                    Button {
                        Task { await searchFlight() }
                    } label: {
                        HStack {
                            if isSearching { ProgressView() }
                            Label(isSearching ? "Ricerca in corso…" : "Cerca volo", systemImage: "magnifyingglass")
                        }.frame(maxWidth: .infinity)
                    }
                    .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
                }

                if let errorText {
                    Section {
                        Label(errorText, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                if searchCompleted {
                    Section("Volo trovato") {
                        LabeledContent("Compagnia", value: airline)
                        LabeledContent("Tratta", value: "\(originCode) → \(destinationCode)")
                        LabeledContent("Partenza", value: departure.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Arrivo", value: arrival.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Terminal", value: terminal)
                        LabeledContent("Gate", value: gate)
                    }
                    Section("Città") {
                        TextField("Città di partenza", text: $originCity)
                        TextField("Città di destinazione", text: $destinationCity)
                    }
                    Section("Dettagli facoltativi") {
                        TextField("Posto", text: $seat)
                    }
                }

                Section {
                    Text("Inserisci numero e data, poi premi Cerca volo. Compagnia, aeroporti, città, orari, terminal e gate vengono compilati dai dati AeroDataBox. Il meteo della destinazione viene caricato automaticamente dopo il salvataggio.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Aggiungi viaggio")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        let status: Flight.Status = terminal == "Da assegnare" && gate == "Da assegnare" ? .scheduled : .onTime
                        let flight = Flight(
                            code: code.uppercased().replacingOccurrences(of: " ", with: ""),
                            airline: airline,
                            originCode: originCode,
                            originCity: originCity,
                            destinationCode: destinationCode,
                            destinationCity: destinationCity,
                            departure: departure,
                            arrival: arrival,
                            terminal: terminal,
                            gate: gate,
                            seat: seat,
                            status: status
                        )
                        trips.add(flight)
                        liveData.refresh(destination: destinationCity, flight: flight)
                        dismiss()
                    }.disabled(!valid)
                }
            }
        }
    }

    @MainActor
    private func searchFlight() async {
        isSearching = true
        searchCompleted = false
        errorText = nil
        defer { isSearching = false }

        do {
            let result = try await liveData.lookupFlight(number: code, date: selectedDate)
            code = result.flightNumber
            airline = result.airline
            originCode = result.originCode
            originCity = result.originCity
            destinationCode = result.destinationCode
            destinationCity = result.destinationCity
            departure = result.departure
            arrival = result.arrival
            terminal = result.terminal
            gate = result.gate
            searchCompleted = true
            await liveData.fetchDestinationWeather(city: result.destinationCity)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription
            errorText = message ?? "Impossibile cercare il volo. Controlla numero, data e connessione internet."
        }
    }
}
