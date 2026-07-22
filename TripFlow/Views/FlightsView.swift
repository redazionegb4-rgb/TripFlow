import SwiftUI

struct FlightsView: View {
    @EnvironmentObject private var trips: TripStore
    @State private var showingAddFlight = false
    var body: some View {
        List {
            Section { summary }
            Section("Viaggi salvati") {
                if trips.flights.isEmpty { ContentUnavailableView("Nessun viaggio",systemImage:"airplane",description:Text("Premi + per aggiungerne uno.")) }
                ForEach(trips.flights) { flight in
                    NavigationLink(destination: FlightDetailView(flight: flight)) { flightRow(flight) }
                        .swipeActions(edge:.trailing,allowsFullSwipe:true){Button(role:.destructive){trips.delete(flight)}label:{Label("Elimina",systemImage:"trash")}}
                        .contextMenu { Button(role:.destructive){trips.delete(flight)}label:{Label("Elimina viaggio",systemImage:"trash")} }
                }.onDelete(perform: trips.delete)
            }
        }.listStyle(.insetGrouped).navigationTitle("I miei viaggi")
        .toolbar { ToolbarItem(placement:.topBarTrailing){Button{showingAddFlight=true}label:{Image(systemName:"plus")}};ToolbarItem(placement:.topBarLeading){EditButton()} }
        .sheet(isPresented:$showingAddFlight){AddFlightView()}
    }
    private var summary: some View { HStack{stat("\(trips.flights.filter{$0.departure>Date()}.count)","In programma");Divider();stat("\(trips.flights.filter{$0.departure<=Date()}.count)","Completati")}.padding(.vertical,8) }
    private func stat(_ value:String,_ label:String)->some View{VStack{Text(value).font(.title.bold());Text(label).font(.caption).foregroundStyle(.secondary)}.frame(maxWidth:.infinity)}
    private func flightRow(_ f:Flight)->some View { VStack(alignment:.leading,spacing:8){HStack{Text(f.code).font(.headline);Spacer();Text(f.status.rawValue).font(.caption.bold()).foregroundStyle(AppTheme.accent)};HStack{Text(f.originCode).font(.title2.bold());Image(systemName:"arrow.right").foregroundStyle(.secondary);Text(f.destinationCode).font(.title2.bold())};Text("\(f.originCity) → \(f.destinationCity)").font(.caption);Text(f.departure.formatted(date:.long,time:.shortened)).font(.caption).foregroundStyle(.secondary)}.padding(.vertical,5) }
}

private struct AddFlightView: View {
    @EnvironmentObject private var trips: TripStore
    @Environment(\.dismiss) private var dismiss
    @State private var code=""; @State private var airline=""; @State private var originCode=""; @State private var originCity=""; @State private var destinationCode=""; @State private var destinationCity=""; @State private var departure=Date().addingTimeInterval(86400); @State private var terminal="Da assegnare"; @State private var gate="Da assegnare"; @State private var seat=""
    var valid:Bool{!code.isEmpty && !originCity.isEmpty && !destinationCity.isEmpty}
    var body:some View{NavigationStack{Form{Section("Volo"){TextField("Numero volo",text:$code).textInputAutocapitalization(.characters);TextField("Compagnia",text:$airline)};Section("Partenza"){TextField("Codice aeroporto, es. FCO",text:$originCode).textInputAutocapitalization(.characters);TextField("Città",text:$originCity);DatePicker("Data e ora",selection:$departure)};Section("Destinazione"){TextField("Codice aeroporto, es. JFK",text:$destinationCode).textInputAutocapitalization(.characters);TextField("Città",text:$destinationCity)};Section("Dettagli"){TextField("Terminal",text:$terminal);TextField("Gate",text:$gate);TextField("Posto",text:$seat)};Section{Text("I dati inseriti vengono salvati sul dispositivo. Meteo e cambi sono recuperati online; gate e ritardi in tempo reale richiedono una chiave API voli configurata nelle Impostazioni.").font(.footnote).foregroundStyle(.secondary)}}.navigationTitle("Aggiungi viaggio").toolbar{ToolbarItem(placement:.cancellationAction){Button("Annulla"){dismiss()}};ToolbarItem(placement:.confirmationAction){Button("Salva"){trips.add(Flight(code:code.uppercased(),airline:airline,originCode:originCode.uppercased(),originCity:originCity,destinationCode:destinationCode.uppercased(),destinationCity:destinationCity,departure:departure,arrival:departure.addingTimeInterval(3*3600),terminal:terminal,gate:gate,seat:seat,status:.scheduled));dismiss()}.disabled(!valid)}}}}
}
