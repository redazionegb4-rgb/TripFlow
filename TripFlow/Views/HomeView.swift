import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var liveData: LiveDataStore
    @EnvironmentObject private var notifications: NotificationManager
    @EnvironmentObject private var trips: TripStore
    @State private var showNotifications = false
    @State private var showConverter = false
    @State private var showDestinationHub = false

    var body: some View {
        ZStack {
            background
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    topBar
                    if let flight = trips.nextFlight { hero(flight); countdown(flight); timeSection(flight); destinationSection(flight) }
                    else { emptyTrip }
                    quickActions
                }
                .padding(18).padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNotifications) { NavigationStack { NotificationsView() } }
        .sheet(isPresented: $showConverter) { NavigationStack { CurrencyConverterView() } }
        .sheet(isPresented: $showDestinationHub) { NavigationStack { DestinationHubView() } }
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
            action("Valigia", "Checklist personale", "suitcase.fill", .orange, { NotificationCenter.default.post(name: .openPackingTab, object: nil) })
            action("Documenti", "Protetti con Face ID", "faceid", .pink, { NotificationCenter.default.post(name: .openDocumentsTab, object: nil) })
            action("Destinazione", "Orari, meteo e servizi", "location.fill", .green, { showDestinationHub = true })
        }}
    }
    private func action(_ title:String,_ subtitle:String,_ icon:String,_ color:Color,_ tap:@escaping()->Void)->some View { Button(action:tap){VStack(alignment:.leading,spacing:12){Image(systemName:icon).font(.title2).foregroundStyle(color);Text(title).font(.headline);Text(subtitle).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)}.frame(maxWidth:.infinity,minHeight:110,alignment:.leading).padding(15).background(.thinMaterial,in:RoundedRectangle(cornerRadius:20))}.buttonStyle(.plain) }


    private func timeSection(_ flight: Flight) -> some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HStack(spacing: 12) {
                timeCard("Ora locale", date: context.date, timeZone: .current, icon: "location.circle.fill")
                timeCard("Ora a destinazione", date: context.date, timeZone: destinationTimeZone(for: flight.destinationCode), icon: "globe.europe.africa.fill")
            }
        }
    }
    private func timeCard(_ title: String, date: Date, timeZone: TimeZone, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(AppTheme.accent)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(formattedTime(date, timeZone: timeZone))
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text(timeZone.identifier.replacingOccurrences(of: "_", with: " ")).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(15).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    private func formattedTime(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }
    private func destinationTimeZone(for airport: String) -> TimeZone {
        let zones: [String: String] = [
            "JFK":"America/New_York", "EWR":"America/New_York", "LGA":"America/New_York",
            "LAX":"America/Los_Angeles", "SFO":"America/Los_Angeles", "MIA":"America/New_York",
            "ORD":"America/Chicago", "BCN":"Europe/Madrid", "MAD":"Europe/Madrid",
            "FCO":"Europe/Rome", "MXP":"Europe/Rome", "LIN":"Europe/Rome", "NAP":"Europe/Rome",
            "LHR":"Europe/London", "LGW":"Europe/London", "CDG":"Europe/Paris", "ORY":"Europe/Paris",
            "DXB":"Asia/Dubai", "DOH":"Asia/Qatar", "HND":"Asia/Tokyo", "NRT":"Asia/Tokyo",
            "SYD":"Australia/Sydney", "GRU":"America/Sao_Paulo", "CUN":"America/Cancun"
        ]
        return TimeZone(identifier: zones[airport.uppercased()] ?? "UTC") ?? .current
    }

    private func destinationSection(_ flight:Flight)->some View { VStack(alignment:.leading,spacing:12){Text("Meteo a destinazione").font(.title3.bold()); if let w=liveData.destinationWeather { HStack{Image(systemName:liveData.symbol(for:w.code)).font(.largeTitle).foregroundStyle(AppTheme.cyan);VStack(alignment:.leading){Text(w.city).font(.headline);Text("\(Int(w.temperature.rounded()))° adesso").font(.title2.bold());if let min=w.minimum,let max=w.maximum{Text("Min \(Int(min.rounded()))° · Max \(Int(max.rounded()))°").font(.caption).foregroundStyle(.secondary)}};Spacer()}.padding(18).background(.thinMaterial,in:RoundedRectangle(cornerRadius:22)) } else { ProgressView("Caricamento meteo di \(flight.destinationCity)…").frame(maxWidth:.infinity,alignment:.leading).padding() } } }
    private var emptyTrip: some View { ContentUnavailableView("Nessun viaggio",systemImage:"airplane",description:Text("Aggiungi un volo dalla sezione Viaggi.")) }
    private var background: some View { LinearGradient(colors:[Color(.systemBackground),AppTheme.accent.opacity(0.07)],startPoint:.top,endPoint:.bottom).ignoresSafeArea() }
}

struct DestinationHubView: View {
    @EnvironmentObject private var liveData: LiveDataStore
    @EnvironmentObject private var trips: TripStore
    var body: some View {
        List {
            if let flight = trips.nextFlight {
                Section("Destinazione") {
                    LabeledContent("Città", value: flight.destinationCity)
                    LabeledContent("Aeroporto", value: flight.destinationCode)
                    if let weather = liveData.destinationWeather {
                        LabeledContent("Meteo", value: "\(Int(weather.temperature.rounded()))° · \(weather.description.capitalized)")
                    }
                }
                Section("Funzioni predisposte") {
                    feature("Luoghi utili", "Ristoranti, farmacie, ospedali, bancomat e parcheggi", "mappin.and.ellipse")
                    feature("Eventi", "Concerti, spettacoli e sport nella città", "ticket.fill")
                    feature("Trasporti", "Percorsi tra aeroporto, hotel e centro", "tram.fill")
                    feature("Numeri utili", "Emergenze, consolati e assistenza", "cross.case.fill")
                }
            } else {
                ContentUnavailableView("Nessuna destinazione", systemImage: "location.slash", description: Text("Aggiungi prima un viaggio."))
            }
        }.navigationTitle("Destinazione").task { liveData.refresh(destination: trips.nextFlight?.destinationCity, flight: trips.nextFlight) }
    }
    private func feature(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(AppTheme.accent).frame(width: 30)
            VStack(alignment: .leading, spacing: 3) { Text(title); Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            Spacer(); Text("Pronto").font(.caption2.bold()).foregroundStyle(AppTheme.accent).padding(.horizontal, 8).padding(.vertical, 5).background(AppTheme.accent.opacity(0.1), in: Capsule())
        }
    }
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
