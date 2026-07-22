import SwiftUI

struct FlightDetailView: View {
    let flight: Flight
    @EnvironmentObject private var liveData: LiveDataStore

    var live: FlightLiveSnapshot? { liveData.live(for: flight) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                routeCard
                if liveData.isLoadingFlight { ProgressView("Aggiornamento dati reali…") }
                infoGrid
                timeline
                if let updated = live?.updatedAt {
                    Text("Ultimo aggiornamento API: \(updated.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(18)
        }
        .navigationTitle(flight.code)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await liveData.fetchFlightStatus(flight) } } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task { await liveData.fetchFlightStatus(flight) }
        .refreshable { await liveData.fetchFlightStatus(flight) }
    }

    private var routeCard: some View {
        VStack(spacing: 22) {
            HStack {
                Text(live?.originCode ?? flight.originCode).font(.system(size: 38, weight: .black, design: .rounded))
                Spacer()
                Image(systemName: "airplane").font(.title2).foregroundStyle(AppTheme.accent)
                Spacer()
                Text(live?.destinationCode ?? flight.destinationCode).font(.system(size: 38, weight: .black, design: .rounded))
            }
            HStack {
                Text(flight.originCity)
                Spacer()
                Text(flight.destinationCity)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(22)
        .background(AppTheme.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 28))
    }

    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            detail("Terminal partenza", live?.departureTerminal ?? flight.terminal, "building.2.fill")
            detail("Gate partenza", live?.departureGate ?? flight.gate, "door.left.hand.open")
            detail("Terminal arrivo", live?.arrivalTerminal ?? "Da assegnare", "building.2")
            detail("Nastro bagagli", live?.baggageBelt ?? "Da assegnare", "suitcase.rolling.fill")
            detail("Aereo", live?.aircraft ?? "Non disponibile", "airplane")
            detail("Stato reale", live?.status ?? flight.status.rawValue, "dot.radiowaves.left.and.right")
        }
    }

    private func detail(_ title: String, _ value: String, _ icon: String) -> some View {
        TravelCard {
            Image(systemName: icon).foregroundStyle(AppTheme.accent)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
    }

    private var timeline: some View {
        TravelCard {
            Text("Orari del volo").font(.headline)
            timelineRow("Partenza programmata", live?.scheduledDeparture ?? flight.departure, true)
            if let revised = live?.revisedDeparture { timelineRow("Partenza aggiornata", revised, true) }
            timelineRow("Arrivo programmato", live?.scheduledArrival ?? flight.arrival, false)
            if let revised = live?.revisedArrival { timelineRow("Arrivo aggiornato", revised, false) }
        }
    }

    private func timelineRow(_ title: String, _ date: Date, _ active: Bool) -> some View {
        HStack(spacing: 12) {
            Circle().fill(active ? AppTheme.accent : Color.secondary.opacity(0.3)).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
