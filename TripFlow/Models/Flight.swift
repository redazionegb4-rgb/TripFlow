import Foundation

struct Flight: Identifiable, Hashable, Codable {
    enum Status: String, Codable, CaseIterable {
        case scheduled = "Programmato"
        case onTime = "In orario"
        case boarding = "Imbarco"
        case delayed = "In ritardo"

        var symbol: String {
            switch self {
            case .scheduled: return "calendar.badge.clock"
            case .onTime: return "checkmark.circle.fill"
            case .boarding: return "person.line.dotted.person.fill"
            case .delayed: return "clock.badge.exclamationmark.fill"
            }
        }
    }

    var id: UUID
    var code: String
    var airline: String
    var originCode: String
    var originCity: String
    var destinationCode: String
    var destinationCity: String
    var departure: Date
    var arrival: Date
    var terminal: String
    var gate: String
    var seat: String
    var status: Status

    init(id: UUID = UUID(), code: String, airline: String, originCode: String, originCity: String, destinationCode: String, destinationCity: String, departure: Date, arrival: Date, terminal: String, gate: String, seat: String, status: Status) {
        self.id = id; self.code = code; self.airline = airline; self.originCode = originCode; self.originCity = originCity
        self.destinationCode = destinationCode; self.destinationCity = destinationCity; self.departure = departure; self.arrival = arrival
        self.terminal = terminal; self.gate = gate; self.seat = seat; self.status = status
    }

    static let demo = Flight(code: "IB2627", airline: "LEVEL", originCode: "BCN", originCity: "Barcellona", destinationCode: "JFK", destinationCity: "New York", departure: Calendar.current.date(byAdding: .day, value: 6, to: .now) ?? .now, arrival: Calendar.current.date(byAdding: .day, value: 6, to: .now.addingTimeInterval(8*3600)) ?? .now, terminal: "1", gate: "Da assegnare", seat: "17A", status: .scheduled)
}
