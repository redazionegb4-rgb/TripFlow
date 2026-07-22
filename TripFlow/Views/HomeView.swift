import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var liveData: LiveDataStore
    @EnvironmentObject private var notifications: NotificationManager
    private let flight = Flight.demo

    var body: some View {
        ZStack {
            background
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    topBar
                    hero
                    countdown
                    quickActions
                    destination
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { liveData.refresh(); notifications.refreshAuthorization() }
        .refreshable { liveData.refresh() }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("TRIPFLOW")
                    .font(.caption.weight(.black))
                    .tracking(2.2)
                    .foregroundStyle(AppTheme.accent)
                Text("Il tuo prossimo viaggio")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }
            Spacer()
            NavigationLink(destination: NotificationsView()) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: notifications.unreadCount > 0 ? "bell.fill" : "bell")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 46, height: 46)
                        .background(.ultraThinMaterial, in: Circle())
                    if notifications.unreadCount > 0 {
                        Text("\(min(notifications.unreadCount, 9))")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 19, height: 19)
                            .background(.red, in: Circle())
                            .offset(x: 2, y: -2)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var hero: some View {
        NavigationLink(destination: FlightDetailView(flight: flight)) {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PROSSIMO VOLO")
                            .font(.caption2.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(.white.opacity(0.65))
                        Text(flight.code)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Label(flight.status.rawValue, systemImage: flight.status.symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.14), in: Capsule())
                }

                HStack {
                    airport(flight.originCode, flight.originCity, alignment: .leading)
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "airplane")
                            .font(.title2.weight(.semibold))
                            .rotationEffect(.degrees(90))
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { _ in
                                Circle().frame(width: 4, height: 4)
                            }
                        }
                        .opacity(0.45)
                    }
                    .foregroundStyle(.white)
                    Spacer()
                    airport(flight.destinationCode, flight.destinationCity, alignment: .trailing)
                }

                Divider().overlay(.white.opacity(0.18))

                HStack {
                    flightMeta("Partenza", flight.departure.formatted(date: .abbreviated, time: .shortened))
                    Spacer()
                    flightMeta("Terminal", flight.terminal)
                    Spacer()
                    flightMeta("Gate", flight.gate)
                }
            }
            .padding(22)
            .background {
                ZStack {
                    LinearGradient(colors: [AppTheme.navy, Color(red: 0.13, green: 0.17, blue: 0.38), AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Circle().fill(.white.opacity(0.08)).frame(width: 190).offset(x: 145, y: -105)
                    Circle().fill(AppTheme.cyan.opacity(0.18)).frame(width: 150).offset(x: -140, y: 115)
                }
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            }
            .shadow(color: AppTheme.accent.opacity(0.22), radius: 24, y: 14)
        }
        .buttonStyle(.plain)
    }

    private func airport(_ code: String, _ city: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 3) {
            Text(code).font(.system(size: 34, weight: .black, design: .rounded))
            Text(city).font(.caption).foregroundStyle(.white.opacity(0.7))
        }
        .foregroundStyle(.white)
    }

    private func flightMeta(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption2).foregroundStyle(.white.opacity(0.6))
            Text(value).font(.caption.weight(.semibold)).foregroundStyle(.white)
        }
    }

    private var countdown: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(AppTheme.accent.opacity(0.12))
                Image(systemName: "timer").font(.title2).foregroundStyle(AppTheme.accent)
            }
            .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text("Mancano 6 giorni")
                    .font(.headline)
                Text("Controlla documenti e valigia prima della partenza")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tutto sotto controllo")
                .font(.title3.bold())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                action("Meteo", weatherText, liveData.weatherSymbol, AppTheme.cyan)
                action("Cambio", exchangeText, "arrow.left.arrow.right", AppTheme.accent)
                action("Valigia", "5 elementi mancanti", "suitcase.fill", .orange)
                action("Documenti", "3 salvati", "doc.fill", .pink)
            }
        }
    }

    private func action(_ title: String, _ subtitle: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 23).stroke(Color.primary.opacity(0.06)) }
    }

    private var destination: some View {
        TravelCard {
            HStack(spacing: 14) {
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(LinearGradient(colors: [AppTheme.accent, AppTheme.cyan], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
                VStack(alignment: .leading, spacing: 4) {
                    Text(liveData.city)
                        .font(.headline)
                    Text(destinationSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
        }
    }

    private var weatherText: String {
        if liveData.isLoading { return "Aggiornamento…" }
        if let value = liveData.temperature { return "\(Int(value.rounded()))° · Dati reali" }
        return "Posizione richiesta"
    }

    private var exchangeText: String {
        guard let rate = liveData.euroToUSD else { return "Aggiornamento…" }
        return String(format: "1 € = %.2f $", rate)
    }

    private var destinationSubtitle: String {
        let time = Date().formatted(date: .omitted, time: .shortened)
        if let value = liveData.temperature { return "Ora locale \(time) · \(Int(value.rounded()))°C" }
        return "Ora locale \(time)"
    }

    private var background: some View {
        LinearGradient(colors: [AppTheme.accent.opacity(0.10), Color.clear, AppTheme.cyan.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}
