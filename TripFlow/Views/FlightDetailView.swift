import SwiftUI

struct FlightDetailView: View {
    let flight: Flight

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TravelCard {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(flight.code).font(.title2.bold())
                            Text(flight.airline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Label(flight.status.rawValue, systemImage: flight.status.symbol)
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                }

                TravelCard {
                    HStack {
                        detailAirport(flight.originCode, flight.originCity, flight.departure)
                        Spacer()
                        Image(systemName: "airplane").font(.title).foregroundStyle(.blue)
                        Spacer()
                        detailAirport(flight.destinationCode, flight.destinationCity, flight.arrival)
                    }
                }

                HStack(spacing: 12) {
                    infoBox("Terminal", flight.terminal, "building.2.fill")
                    infoBox("Gate", flight.gate, "rectangle.portrait.and.arrow.forward.fill")
                }

                TravelCard {
                    Label("Monitoraggio in tempo reale", systemImage: "dot.radiowaves.left.and.right")
                        .font(.headline)
                    Text("Il collegamento ai dati live, ai ritardi e ai cambi gate sarà attivato dopo la scelta del provider API.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 5)
                }
            }
            .padding()
        }
        .navigationTitle("Dettagli volo")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailAirport(_ code: String, _ city: String, _ date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(code).font(.system(size: 30, weight: .bold, design: .rounded))
            Text(city).font(.caption).foregroundStyle(.secondary)
            Text(date.formatted(date: .omitted, time: .shortened)).font(.headline)
        }
    }

    private func infoBox(_ title: String, _ value: String, _ icon: String) -> some View {
        TravelCard {
            Image(systemName: icon).foregroundStyle(.blue)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold())
        }
    }
}
