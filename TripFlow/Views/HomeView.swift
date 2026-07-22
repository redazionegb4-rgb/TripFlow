import SwiftUI

struct HomeView: View {
    private let flight = Flight.demo

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                flightHero
                quickGrid
                destinationCard
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 30)
        }
        .background(background)
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Buongiorno")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Dove andiamo?")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
            }
            Spacer()
            Image(systemName: "bell.fill")
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: Circle())
        }
        .padding(.top, 14)
    }

    private var flightHero: some View {
        NavigationLink(destination: FlightDetailView(flight: flight)) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Label(flight.code, systemImage: "airplane.departure")
                        .font(.headline)
                    Spacer()
                    Label(flight.status.rawValue, systemImage: flight.status.symbol)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.green.opacity(0.18), in: Capsule())
                }

                HStack(alignment: .center) {
                    airport(code: flight.originCode, city: flight.originCity, alignment: .leading)
                    Spacer()
                    VStack(spacing: 7) {
                        Image(systemName: "airplane")
                            .font(.title2)
                        Capsule().frame(height: 2).opacity(0.35)
                    }
                    .frame(maxWidth: 100)
                    Spacer()
                    airport(code: flight.destinationCode, city: flight.destinationCity, alignment: .trailing)
                }

                HStack {
                    Label(flight.departure.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    Spacer()
                    Text("Gate \(flight.gate)")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            .foregroundStyle(.white)
            .padding(22)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.03, green: 0.16, blue: 0.32), Color(red: 0.08, green: 0.48, blue: 0.76)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 30, style: .continuous)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
    }

    private func airport(code: String, city: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 3) {
            Text(code).font(.system(size: 31, weight: .bold, design: .rounded))
            Text(city).font(.caption).opacity(0.8)
        }
    }

    private var quickGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickActionCard(title: "Meteo", subtitle: "New York · 19°", icon: "cloud.sun.fill")
            QuickActionCard(title: "Ora locale", subtitle: "06:25", icon: "clock.fill")
            QuickActionCard(title: "Cambio", subtitle: "1 € = 1,09 $", icon: "eurosign.arrow.circlepath")
            QuickActionCard(title: "Checklist", subtitle: "8 di 14 pronti", icon: "checklist")
        }
    }

    private var destinationCard: some View {
        TravelCard {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(Color.blue.opacity(0.14))
                    Image(systemName: "map.fill").font(.title).foregroundStyle(.blue)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Esplora la destinazione").font(.headline)
                    Text("Trasporti, numeri utili, mappe e informazioni per New York.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.10), Color.clear, Color.cyan.opacity(0.06)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        TravelCard {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 42, height: 42)
                .background(Color.blue.opacity(0.13), in: RoundedRectangle(cornerRadius: 13))
            Text(title).font(.headline).padding(.top, 8)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
    }
}
