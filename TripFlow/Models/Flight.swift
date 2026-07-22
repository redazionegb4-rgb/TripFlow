import Foundation

struct Flight: Identifiable, Hashable {
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
    let status: FlightStatus
}

enum FlightStatus: String, Hashable {
    case onTime = "In orario"
    case delayed = "In ritardo"
    case boarding = "Imbarco"

    var symbol: String {
        switch self {
        case .onTime: return "checkmark.circle.fill"
        case .delayed: return "clock.badge.exclamationmark.fill"
        case .boarding: return "person.crop.circle.badge.checkmark"
        }
    }
}

extension Flight {
    static let demo = Flight(
        code: "LV 0137",
        airline: "LEVEL",
        originCode: "BCN",
        originCity: "Barcellona",
        destinationCode: "JFK",
        destinationCity: "New York",
        departure: Calendar.current.date(bySettingHour: 15, minute: 40, second: 0, of: Calendar.current.date(byAdding: .day, value: 5, to: Date())!)!,
        arrival: Calendar.current.date(bySettingHour: 19, minute: 10, second: 0, of: Calendar.current.date(byAdding: .day, value: 5, to: Date())!)!,
        terminal: "1",
        gate: "A12",
        status: .onTime
    )
}
