import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var liveData: LiveDataStore
    @EnvironmentObject private var notifications: NotificationManager
    @EnvironmentObject private var trips: TripStore
    @State private var showNotifications = false
    @State private var showConverter = false

    var body: some View {
        ZStack {
            background
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    topBar
                    if let flight = trips.nextFlight { hero(flight); countdown(flight); destinationSection(flight) }
                    else { emptyTrip }
                    quickActions
                }
                .padding(18).padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNotifications) { NavigationStack { NotificationsView() } }
        .sheet(isPresented: $showConverter) { NavigationStack { CurrencyConverterView() } }
        .task { liveData.refresh(destination: trips.nextFlight?.destinationCity, flight: trips.nextFlight); notifications.refreshAuthorization() }
        .refreshable { liveData.refresh(destination: trips.nextFlight?.destinationCity, flight: trips.nextFlight) }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("TRIPFLOW").font(.caption.weight(.black)).tracking(2).foregroundStyle(AppTheme.accent)
                Text("Il tuo prossimo viaggio").font(.system(size: 27, weight: .bold, design: .rounded))
            }
            Spacer()
            Button { showNotifications = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: notifications.unreadCount > 0 ? "bell.fill" : "bell").font(.system(size: 18, weight: .semibold)).frame(width: 46, height: 46).background(.ultraThinMaterial, in: Circle())
                    if notifications.unreadCount > 0 { Text("\(min(notifications.unreadCount,9))").font(.caption2.bold()).foregroundStyle(.white).frame(width: 19,height:19).background(.red,in:Circle()).offset(x:2,y:-2) }
                }
            }.buttonStyle(.plain)
        }
    }

    private func hero(_ flight: Flight) -> some View {
        NavigationLink(destination: FlightDetailView(flight: flight)) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(flight.code).font(.headline)
                    Spacer()
                    let live = liveData.live(for: flight)
                    Label(live?.status ?? flight.status.rawValue, systemImage: live == nil ? flight.status.symbol : "dot.radiowaves.left.and.right")
                        .font(.caption.bold())
                        .padding(8)
                        .background(.white.opacity(0.15), in: Capsule())
                }
                HStack { airport(flight.originCode, flight.originCity); Spacer(); Image(systemName:"airplane").font(.title2).rotationEffect(.degrees(90)); Spacer(); airport(flight.destinationCode, flight.destinationCity) }
                Divider().overlay(.white.opacity(0.2))
                let live = liveData.live(for: flight)
                HStack {
                    meta("Partenza", (live?.revisedDeparture ?? live?.scheduledDeparture ?? flight.departure).formatted(date:.abbreviated,time:.shortened))
                    Spacer()
                    meta("Terminal", live?.departureTerminal ?? flight.terminal)
                    Spacer()
                    meta("Gate", live?.departureGate ?? flight.gate)
                }
            }.foregroundStyle(.white).padding(22)
            .background(LinearGradient(colors:[AppTheme.navy,AppTheme.accent],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:30))
        }.buttonStyle(.plain)
    }
    private func airport(_ code:String,_ city:String)->some View { VStack(alignment:.leading){Text(code).font(.system(size:32,weight:.black,design:.rounded));Text(city).font(.caption).opacity(0.75)} }
    private func meta(_ title:String,_ value:String)->some View { VStack(alignment:.leading){Text(title).font(.caption2).opacity(0.65);Text(value).font(.caption.bold())} }
    private func countdown(_ flight:Flight)->some View { let days=max(0,Calendar.current.dateComponents([.day],from:Date(),to:flight.departure).day ?? 0); return Label("Mancano \(days) giorni alla partenza",systemImage:"timer").font(.headline).frame(maxWidth:.infinity,alignment:.leading).padding(17).background(.thinMaterial,in:RoundedRectangle(cornerRadius:20)) }

    private var quickActions: some View {
        VStack(alignment:.leading,spacing:12){ Text("Strumenti di viaggio").font(.title3.bold()); LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:12){
            action("Meteo attuale", liveData.currentWeather.map{"\(Int($0.temperature.rounded()))° · \($0.city)"} ?? "Aggiornamento…", liveData.symbol(for: liveData.currentWeather?.code), AppTheme.cyan, {})
            action("Converti valuta", "Calcola quanto valgono i soldi", "eurosign.arrow.circlepath", AppTheme.accent, {showConverter=true})
            action("Valigia", "Checklist del viaggio", "suitcase.fill", .orange, {})
            action("Documenti", "Protetti con Face ID", "faceid", .pink, {})
        }}
    }
    private func action(_ title:String,_ subtitle:String,_ icon:String,_ color:Color,_ tap:@escaping()->Void)->some View { Button(action:tap){VStack(alignment:.leading,spacing:12){Image(systemName:icon).font(.title2).foregroundStyle(color);Text(title).font(.headline);Text(subtitle).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)}.frame(maxWidth:.infinity,minHeight:110,alignment:.leading).padding(15).background(.thinMaterial,in:RoundedRectangle(cornerRadius:20))}.buttonStyle(.plain) }

    private func destinationSection(_ flight:Flight)->some View { VStack(alignment:.leading,spacing:12){Text("Meteo a destinazione").font(.title3.bold()); if let w=liveData.destinationWeather { HStack{Image(systemName:liveData.symbol(for:w.code)).font(.largeTitle).foregroundStyle(AppTheme.cyan);VStack(alignment:.leading){Text(w.city).font(.headline);Text("\(Int(w.temperature.rounded()))° adesso").font(.title2.bold());if let min=w.minimum,let max=w.maximum{Text("Min \(Int(min.rounded()))° · Max \(Int(max.rounded()))°").font(.caption).foregroundStyle(.secondary)}};Spacer()}.padding(18).background(.thinMaterial,in:RoundedRectangle(cornerRadius:22)) } else { ProgressView("Caricamento meteo di \(flight.destinationCity)…").frame(maxWidth:.infinity,alignment:.leading).padding() } } }
    private var emptyTrip: some View { ContentUnavailableView("Nessun viaggio",systemImage:"airplane",description:Text("Aggiungi un volo dalla sezione Viaggi.")) }
    private var background: some View { LinearGradient(colors:[Color(.systemBackground),AppTheme.accent.opacity(0.07)],startPoint:.top,endPoint:.bottom).ignoresSafeArea() }
}

struct CurrencyConverterView: View {
    @EnvironmentObject private var liveData: LiveDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var amount = "100"
    @State private var from = "EUR"
    @State private var to = "USD"
    private let currencies = ["EUR","USD","GBP","CHF","CAD","AUD","JPY","MXN","BRL"]
    var value: Double { Double(amount.replacingOccurrences(of:",",with:".")) ?? 0 }
    var converted: Double? { liveData.convert(value, from: from, to: to) }
    var body: some View { Form {
        Section("Importo") { TextField("0,00",text:$amount).keyboardType(.decimalPad).font(.title2.bold()) }
        Section("Valute") { Picker("Da",selection:$from){ForEach(currencies,id:\.self){Text($0)}};Picker("A",selection:$to){ForEach(currencies,id:\.self){Text($0)}};Button("Inverti valute"){swap(&from,&to)} }
        Section("Risultato") { Text(converted.map{String(format:"%.2f %@",$0,to)} ?? "Cambio non disponibile").font(.system(size:30,weight:.bold,design:.rounded));Text("Tassi aggiornati online. Il valore applicato dalla banca può variare.").font(.footnote).foregroundStyle(.secondary) }
    }.navigationTitle("Cambio valuta").toolbar{ToolbarItem(placement:.topBarTrailing){Button("Chiudi"){dismiss()}}}.task{liveData.refresh()} }
}
