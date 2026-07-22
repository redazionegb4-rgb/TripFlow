import SwiftUI

struct FlightDetailView: View {
    let flight: Flight

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                routeCard
                infoGrid
                timeline
            }
            .padding(18)
        }
        .navigationTitle(flight.code)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var routeCard: some View {
        VStack(spacing: 22) {
            HStack {
                Text(flight.originCode).font(.system(size: 38, weight: .black, design: .rounded))
                Spacer()
                Image(systemName: "airplane").font(.title2).foregroundStyle(AppTheme.accent)
                Spacer()
                Text(flight.destinationCode).font(.system(size: 38, weight: .black, design: .rounded))
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
            detail("Terminal", flight.terminal, "building.2.fill")
            detail("Gate", flight.gate, "door.left.hand.open")
            detail("Posto", flight.seat, "chair.lounge.fill")
            detail("Stato", flight.status.rawValue, flight.status.symbol)
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
            Text("Programma").font(.headline)
            timelineRow("Partenza", flight.departure.formatted(date: .abbreviated, time: .shortened), true)
            timelineRow("Arrivo previsto", flight.arrival.formatted(date: .abbreviated, time: .shortened), false)
        }
    }

    private func timelineRow(_ title: String, _ value: String, _ active: Bool) -> some View {
        HStack(spacing: 12) {
            Circle().fill(active ? AppTheme.accent : Color.secondary.opacity(0.3)).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(value).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
