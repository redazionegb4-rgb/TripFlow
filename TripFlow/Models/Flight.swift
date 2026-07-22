import Foundation

struct Flight: Identifiable, Hashable {
    enum Status: String {
        case onTime = "In orario"
        case boarding = "Imbarco"
        case delayed = "In ritardo"

        var symbol: String {
            switch self {
            case .onTime: return "checkmark.circle.fill"
            case .boarding: return "person.line.dotted.person.fill"
            case .delayed: return "clock.badge.exclamationmark.fill"
            }
        }
    }

    let id = UUID()
    let code: String
    let airline: String
    let originCode: String
    let originCity: String
    let destinationCode: String
    let destinationCity: String
    let departure: Date
    let arrival: Date
    let terminal: String
    let gate: String
    let seat: String
    let status: Status

    static let demo = Flight(
        code: "LEVEL IB2627",
        airline: "LEVEL",
        originCode: "BCN",
        originCity: "Barcellona",
        destinationCode: "JFK",
        destinationCity: "New York",
        departure: Calendar.current.date(byAdding: .day, value: 6, to: .now) ?? .now,
        arrival: Calendar.current.date(byAdding: .hour, value: 15, to: .now) ?? .now,
        terminal: "1",
        gate: "D18",
        seat: "17A",
        status: .onTime
    )
}
