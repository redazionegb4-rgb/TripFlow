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
            LinearGradient(colors: [Color(.systemBackground), AppTheme.accent.opacity(0.08)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    topBar
                    if let flight = trips.nextFlight {
                        hero(flight)
                        timeSection(flight)
                        destinationWeather(flight)
                    } else { emptyTrip }
                    tools
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNotifications) { NavigationStack { NotificationsView() } }
        .sheet(isPresented: $showConverter) { NavigationStack { CurrencyConverterView() } }
        .sheet(isPresented: $showDestinationHub) { NavigationStack { DestinationHubView() } }
        .task {
            liveData.refresh(destination: trips.nextFlight?.destinationCity, flight: trips.nextFlight)
            notifications.refreshAuthorization()
        }
        .refreshable { liveData.refresh(destination: trips.nextFlight?.destinationCity, flight: trips.nextFlight) }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TRIPFLOW").font(.caption.weight(.black)).tracking(2.2).foregroundStyle(AppTheme.accent)
                Text("Il tuo viaggio, tutto qui")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
            }
            Spacer()
            Button { showNotifications = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: notifications.unreadCount > 0 ? "bell.fill" : "bell")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 46, height: 46)
                        .background(.ultraThinMaterial, in: Circle())
                    if notifications.unreadCount > 0 {
                        Text("\(min(notifications.unreadCount, 9))")
                            .font(.caption2.bold()).foregroundStyle(.white)
                            .frame(width: 19, height: 19).background(.red, in: Circle()).offset(x: 2, y: -2)
                    }
                }
            }.buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private func hero(_ flight: Flight) -> some View {
        NavigationLink(destination: FlightDetailView(flight: flight)) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("PROSSIMO VOLO").font(.caption2.bold()).tracking(1.4).opacity(0.7)
                        Text(flight.code).font(.title3.bold())
                    }
                    Spacer()
                    Text(liveData.live(for: flight)?.status ?? flight.status.rawValue)
                        .font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 7)
                        .background(.white.opacity(0.16), in: Capsule())
                }
                HStack(alignment: .center) {
                    airport(flight.originCode, flight.originCity, .leading)
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "airplane").font(.title2).rotationEffect(.degrees(90))
                        Text("\(daysUntil(flight.departure)) giorni").font(.caption2.bold()).opacity(0.75)
                    }
                    Spacer()
                    airport(flight.destinationCode, flight.destinationCity, .trailing)
                }
                Divider().overlay(.white.opacity(0.24))
                HStack {
                    heroMeta("Partenza", italianDate(liveData.live(for: flight)?.revisedDeparture ?? flight.departure))
                    Spacer()
                    heroMeta("Terminal", liveData.live(for: flight)?.departureTerminal ?? flight.terminal)
                    Spacer()
                    heroMeta("Gate", liveData.live(for: flight)?.departureGate ?? flight.gate)
                }
            }
            .foregroundStyle(.white).padding(22)
            .background(LinearGradient(colors: [AppTheme.navy, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 30))
        }.buttonStyle(.plain)
    }

    private func airport(_ code: String, _ city: String, _ alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(code).font(.system(size: 34, weight: .black, design: .rounded))
            Text(city).font(.caption).opacity(0.75).lineLimit(1)
        }
    }
    private func heroMeta(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) { Text(title).font(.caption2).opacity(0.65); Text(value).font(.caption.bold()).lineLimit(1) }
    }
    private func daysUntil(_ date: Date) -> Int { max(0, Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0) }

    private func timeSection(_ flight: Flight) -> some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HStack(spacing: 12) {
                timeCard("Ora locale", context.date, .current, "location.circle.fill")
                timeCard("Ora a \(flight.destinationCity)", context.date, destinationTimeZone(for: flight.destinationCode), "globe.europe.africa.fill")
            }
        }
    }
    private func timeCard(_ title: String, _ date: Date, _ zone: TimeZone, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon).foregroundStyle(AppTheme.accent)
            Text(title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            Text(timeString(date, zone)).font(.system(size: 25, weight: .bold, design: .rounded))
            Text(zone.abbreviation() ?? zone.identifier).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }

    private func destinationWeather(_ flight: Flight) -> some View {
        Button { showDestinationHub = true } label: {
            HStack(spacing: 16) {
                Image(systemName: liveData.symbol(for: liveData.destinationWeather?.code))
                    .font(.system(size: 30)).foregroundStyle(AppTheme.cyan).frame(width: 48, height: 48)
                    .background(AppTheme.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Destinazione").font(.caption).foregroundStyle(.secondary)
                    Text(flight.destinationCity).font(.headline)
                    if let weather = liveData.destinationWeather {
                        Text("\(Int(weather.temperature.rounded()))° · \(weather.description.capitalized)").font(.subheadline).foregroundStyle(.secondary)
                    } else { Text("Aggiornamento meteo…").font(.subheadline).foregroundStyle(.secondary) }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
        }.buttonStyle(.plain)
    }

    private var tools: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strumenti").font(.title3.bold())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                tool("Cambio valuta", "Converti subito", "eurosign.arrow.circlepath", AppTheme.accent) { showConverter = true }
                tool("Valigia", "Crea la checklist", "suitcase.fill", .orange) { NotificationCenter.default.post(name: .openPackingTab, object: nil) }
                tool("Documenti", "Protetti con Face ID", "faceid", .pink) { NotificationCenter.default.post(name: .openDocumentsTab, object: nil) }
                tool("Scopri", "Servizi e informazioni", "sparkles", .green) { showDestinationHub = true }
            }
        }
    }
    private func tool(_ title: String, _ subtitle: String, _ icon: String, _ color: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 11) {
                Image(systemName: icon).font(.title2).foregroundStyle(color)
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 106, alignment: .leading).padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
        }.buttonStyle(.plain)
    }

    private var emptyTrip: some View { ContentUnavailableView("Nessun viaggio", systemImage: "airplane", description: Text("Aggiungi un volo dalla sezione Viaggi.")) }

    private func italianDate(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "it_IT"); f.dateFormat = "d MMM, HH:mm"; return f.string(from: date)
    }
    private func timeString(_ date: Date, _ zone: TimeZone) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "it_IT"); f.timeZone = zone; f.dateFormat = "HH:mm"; return f.string(from: date)
    }
    private func destinationTimeZone(for airport: String) -> TimeZone {
        let zones = ["JFK":"America/New_York","EWR":"America/New_York","LGA":"America/New_York","LAX":"America/Los_Angeles","SFO":"America/Los_Angeles","MIA":"America/New_York","ORD":"America/Chicago","BCN":"Europe/Madrid","MAD":"Europe/Madrid","FCO":"Europe/Rome","MXP":"Europe/Rome","LIN":"Europe/Rome","NAP":"Europe/Rome","LHR":"Europe/London","LGW":"Europe/London","CDG":"Europe/Paris","ORY":"Europe/Paris","DXB":"Asia/Dubai","DOH":"Asia/Qatar","HND":"Asia/Tokyo","NRT":"Asia/Tokyo","SYD":"Australia/Sydney","GRU":"America/Sao_Paulo","CUN":"America/Cancun"]
        return TimeZone(identifier: zones[airport.uppercased()] ?? "UTC") ?? .current
    }
}

struct DestinationHubView: View {
    @EnvironmentObject private var liveData: LiveDataStore
    @EnvironmentObject private var trips: TripStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let flight = trips.nextFlight {
                    destinationHeader(flight)
                    VStack(spacing: 12) {
                        NavigationLink(destination: DestinationWeatherPage()) { row("Meteo", "Previsioni e condizioni della città", "cloud.sun.fill", AppTheme.cyan) }
                        NavigationLink(destination: PlacesPage()) { row("Luoghi utili", "Ristoranti, farmacie, ospedali e altro", "mappin.and.ellipse", .green) }
                        NavigationLink(destination: EventsPage()) { row("Eventi", "Concerti, spettacoli e sport", "ticket.fill", .orange) }
                        NavigationLink(destination: TransportPage()) { row("Trasporti", "Percorsi, metro, taxi e aeroporto", "tram.fill", AppTheme.accent) }
                        NavigationLink(destination: EmergencyPage()) { row("Numeri utili", "Emergenze, consolati e assistenza", "cross.case.fill", .red) }
                    }
                } else {
                    ContentUnavailableView("Nessuna destinazione", systemImage: "location.slash", description: Text("Aggiungi prima un viaggio."))
                }
            }.padding(18)
        }
        .navigationTitle("Scopri la destinazione")
        .navigationBarTitleDisplayMode(.inline)
        .task { liveData.refresh(destination: trips.nextFlight?.destinationCity, flight: trips.nextFlight) }
    }

    private func destinationHeader(_ flight: Flight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(flight.destinationCode).font(.system(size: 40, weight: .black, design: .rounded))
            Text(flight.destinationCity).font(.title2.bold())
            if let w = liveData.destinationWeather { Text("\(Int(w.temperature.rounded()))° · \(w.description.capitalized)").foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(22)
        .background(LinearGradient(colors: [AppTheme.accent.opacity(0.20), AppTheme.cyan.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 26))
    }
    private func row(_ title: String, _ subtitle: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(color).frame(width: 44, height: 44).background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 3) { Text(title).font(.headline); Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(15).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct DestinationWeatherPage: View {
    @EnvironmentObject private var liveData: LiveDataStore
    @EnvironmentObject private var trips: TripStore
    var body: some View { List { if let w = liveData.destinationWeather { Section("Condizioni attuali") { LabeledContent("Città", value: w.city); LabeledContent("Temperatura", value: "\(Int(w.temperature.rounded()))°"); LabeledContent("Condizioni", value: w.description.capitalized); if let h = w.humidity { LabeledContent("Umidità", value: "\(h)%") }; if let wind = w.windSpeed { LabeledContent("Vento", value: String(format: "%.1f m/s", wind)) } } } else { ContentUnavailableView("Meteo non disponibile", systemImage: "cloud.slash") } }.navigationTitle("Meteo").task { if let c = trips.nextFlight?.destinationCity { await liveData.fetchDestinationWeather(city: c) } } }
}
private struct PlacesPage: View { var body: some View { ContentUnavailableView("Luoghi utili", systemImage: "mappin.and.ellipse", description: Text("Pagina pronta per Google Places o MapKit." )).navigationTitle("Luoghi utili") } }
private struct EventsPage: View { var body: some View { ContentUnavailableView("Eventi", systemImage: "ticket.fill", description: Text("Pagina pronta per Ticketmaster." )).navigationTitle("Eventi") } }
private struct TransportPage: View { var body: some View { ContentUnavailableView("Trasporti", systemImage: "tram.fill", description: Text("Pagina pronta per percorsi, metro e taxi." )).navigationTitle("Trasporti") } }
private struct EmergencyPage: View { var body: some View { ContentUnavailableView("Numeri utili", systemImage: "cross.case.fill", description: Text("Pagina pronta per emergenze e consolati." )).navigationTitle("Numeri utili") } }

struct CurrencyConverterView: View {
    @EnvironmentObject private var liveData: LiveDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var amount = "100"
    @State private var from = "EUR"
    @State private var to = "USD"
    private let currencies = ["EUR","USD","GBP","CHF","CAD","AUD","JPY","MXN","BRL"]
    private var value: Double { Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var converted: Double? { liveData.convert(value, from: from, to: to) }
    var body: some View {
        Form {
            Section("Importo") { TextField("0,00", text: $amount).keyboardType(.decimalPad).font(.title2.bold()) }
            Section("Valute") { Picker("Da", selection: $from) { ForEach(currencies, id: \.self) { Text($0) } }; Picker("A", selection: $to) { ForEach(currencies, id: \.self) { Text($0) } }; Button("Inverti valute") { swap(&from, &to) } }
            Section("Risultato") { Text(converted.map { String(format: "%.2f %@", $0, to) } ?? "Cambio non disponibile").font(.system(size: 30, weight: .bold, design: .rounded)); Text("Tassi aggiornati online. Il valore applicato dalla banca può variare.").font(.footnote).foregroundStyle(.secondary) }
        }
        .navigationTitle("Cambio valuta")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Chiudi") { dismiss() } } }
        .task { liveData.refresh() }
    }
}
