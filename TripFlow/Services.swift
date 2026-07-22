import Foundation
import CoreLocation
import UserNotifications

@MainActor
final class TripStore: ObservableObject {
    @Published var flights: [Flight] { didSet { save() } }
    private let key = "tripflow.flights.v4"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Flight].self, from: data) {
            flights = saved
        } else {
            flights = [Flight.demo]
        }
    }

    var nextFlight: Flight? {
        flights.filter { $0.departure > Date() }.sorted { $0.departure < $1.departure }.first ?? flights.first
    }

    func add(_ flight: Flight) { flights.append(flight) }
    func delete(at offsets: IndexSet) { flights.remove(atOffsets: offsets) }
    func delete(_ flight: Flight) { flights.removeAll { $0.id == flight.id } }
    private func save() {
        if let data = try? JSONEncoder().encode(flights) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct WeatherSnapshot: Equatable {
    let city: String
    let temperature: Double
    let code: Int
    let description: String
    let minimum: Double?
    let maximum: Double?
    let humidity: Int?
    let windSpeed: Double?
}

struct FlightLiveSnapshot: Equatable {
    let flightNumber: String
    let status: String
    let airline: String?
    let originCode: String?
    let destinationCode: String?
    let scheduledDeparture: Date?
    let revisedDeparture: Date?
    let scheduledArrival: Date?
    let revisedArrival: Date?
    let departureTerminal: String?
    let departureGate: String?
    let arrivalTerminal: String?
    let arrivalGate: String?
    let baggageBelt: String?
    let aircraft: String?
    let updatedAt: Date?
}

@MainActor
final class LiveDataStore: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentWeather: WeatherSnapshot?
    @Published var destinationWeather: WeatherSnapshot?
    @Published var rates: [String: Double] = [:]
    @Published var liveFlights: [UUID: FlightLiveSnapshot] = [:]
    @Published var isLoading = false
    @Published var isLoadingFlight = false
    @Published var errorMessage: String?

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refresh(destination: String? = nil, flight: Flight? = nil) {
        errorMessage = nil
        isLoading = true
        Task {
            await fetchRates()
            if let destination, !destination.isEmpty {
                await fetchDestinationWeather(city: destination)
            }
            if let flight {
                await fetchFlightStatus(flight)
            }
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        default:
            isLoading = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task {
            await fetchCurrentWeather(location)
            isLoading = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        errorMessage = "Posizione non disponibile."
    }

    private func fetchCurrentWeather(_ location: CLLocation) async {
        let name = (try? await CLGeocoder().reverseGeocodeLocation(location).first?.locality) ?? "Posizione attuale"
        currentWeather = await weather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, fallbackCity: name)
    }

    func fetchDestinationWeather(city: String) async {
        guard let encoded = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(encoded)&appid=\(APIConfig.openWeatherKey)&units=metric&lang=it") else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            try validate(response)
            let result = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
            destinationWeather = result.snapshot(fallbackCity: city)
        } catch {
            errorMessage = "Impossibile aggiornare il meteo della destinazione."
        }
    }

    private func weather(latitude: Double, longitude: Double, fallbackCity: String) async -> WeatherSnapshot? {
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(APIConfig.openWeatherKey)&units=metric&lang=it") else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            try validate(response)
            let result = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
            return result.snapshot(fallbackCity: fallbackCity)
        } catch {
            return nil
        }
    }

    private func fetchRates() async {
        guard let url = URL(string: "https://v6.exchangerate-api.com/v6/\(APIConfig.exchangeRateKey)/latest/EUR") else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            try validate(response)
            let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            guard decoded.result == "success", let values = decoded.conversionRates else {
                throw URLError(.badServerResponse)
            }
            rates = values
        } catch {
            errorMessage = "Impossibile aggiornare i cambi valuta."
        }
    }

    func fetchFlightStatus(_ flight: Flight) async {
        isLoadingFlight = true
        defer { isLoadingFlight = false }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: flight.departure)
        let number = flight.code.replacingOccurrences(of: " ", with: "")

        guard let encoded = number.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://aerodatabox.p.rapidapi.com/flights/number/\(encoded)/\(date)?withLocation=false") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(APIConfig.aeroDataBoxHost, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(APIConfig.aeroDataBoxKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validate(response)
            let decoded = try JSONDecoder().decode([AeroFlight].self, from: data)
            guard let selected = decoded.first(where: {
                ($0.departure?.airport?.iata ?? "").uppercased() == flight.originCode.uppercased() &&
                ($0.arrival?.airport?.iata ?? "").uppercased() == flight.destinationCode.uppercased()
            }) ?? decoded.first else {
                errorMessage = "Nessun dato live trovato per questo volo."
                return
            }
            liveFlights[flight.id] = selected.snapshot
        } catch {
            errorMessage = "Dati volo non disponibili. Controlla numero e data del volo."
        }
    }

    func live(for flight: Flight) -> FlightLiveSnapshot? { liveFlights[flight.id] }

    func convert(_ amount: Double, from: String, to: String) -> Double? {
        if from == to { return amount }
        let inEUR = from == "EUR" ? amount : rates[from].map { amount / $0 }
        guard let inEUR else { return nil }
        return to == "EUR" ? inEUR : rates[to].map { inEUR * $0 }
    }

    func symbol(for code: Int?) -> String {
        guard let code else { return "cloud.fill" }
        switch code {
        case 200...232: return "cloud.bolt.rain.fill"
        case 300...321: return "cloud.drizzle.fill"
        case 500...531: return "cloud.rain.fill"
        case 600...622: return "cloud.snow.fill"
        case 701...781: return "cloud.fog.fill"
        case 800: return "sun.max.fill"
        case 801...804: return "cloud.sun.fill"
        default: return "cloud.fill"
        }
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

private struct OpenWeatherResponse: Decodable {
    let name: String
    let weather: [Weather]
    let main: Main
    let wind: Wind?

    struct Weather: Decodable { let id: Int; let description: String }
    struct Main: Decodable {
        let temp: Double
        let tempMin: Double?
        let tempMax: Double?
        let humidity: Int?
        enum CodingKeys: String, CodingKey {
            case temp, humidity
            case tempMin = "temp_min"
            case tempMax = "temp_max"
        }
    }
    struct Wind: Decodable { let speed: Double }

    func snapshot(fallbackCity: String) -> WeatherSnapshot {
        WeatherSnapshot(
            city: name.isEmpty ? fallbackCity : name,
            temperature: main.temp,
            code: weather.first?.id ?? 800,
            description: weather.first?.description.capitalized ?? "Meteo disponibile",
            minimum: main.tempMin,
            maximum: main.tempMax,
            humidity: main.humidity,
            windSpeed: wind?.speed
        )
    }
}

private struct ExchangeRateResponse: Decodable {
    let result: String
    let conversionRates: [String: Double]?
    enum CodingKeys: String, CodingKey {
        case result
        case conversionRates = "conversion_rates"
    }
}

private struct AeroFlight: Decodable {
    let number: String?
    let status: String?
    let codeshareStatus: String?
    let departure: AeroMovement?
    let arrival: AeroMovement?
    let aircraft: AeroAircraft?
    let airline: AeroAirline?
    let lastUpdatedUtc: String?

    var snapshot: FlightLiveSnapshot {
        FlightLiveSnapshot(
            flightNumber: number ?? "",
            status: status ?? "Sconosciuto",
            airline: airline?.name,
            originCode: departure?.airport?.iata,
            destinationCode: arrival?.airport?.iata,
            scheduledDeparture: AeroDateParser.date(departure?.scheduledTime?.utc ?? departure?.scheduledTime?.local),
            revisedDeparture: AeroDateParser.date(departure?.revisedTime?.utc ?? departure?.predictedTime?.utc ?? departure?.actualTime?.utc),
            scheduledArrival: AeroDateParser.date(arrival?.scheduledTime?.utc ?? arrival?.scheduledTime?.local),
            revisedArrival: AeroDateParser.date(arrival?.revisedTime?.utc ?? arrival?.predictedTime?.utc ?? arrival?.actualTime?.utc),
            departureTerminal: departure?.terminal,
            departureGate: departure?.gate,
            arrivalTerminal: arrival?.terminal,
            arrivalGate: arrival?.gate,
            baggageBelt: arrival?.baggageBelt,
            aircraft: aircraft?.model,
            updatedAt: AeroDateParser.date(lastUpdatedUtc)
        )
    }
}

private struct AeroMovement: Decodable {
    let airport: AeroAirport?
    let scheduledTime: AeroTime?
    let revisedTime: AeroTime?
    let predictedTime: AeroTime?
    let actualTime: AeroTime?
    let terminal: String?
    let gate: String?
    let baggageBelt: String?
}
private struct AeroAirport: Decodable { let iata: String?; let icao: String?; let name: String? }
private struct AeroTime: Decodable { let utc: String?; let local: String? }
private struct AeroAircraft: Decodable { let model: String? }
private struct AeroAirline: Decodable { let name: String? }

private enum AeroDateParser {
    static func date(_ value: String?) -> Date? {
        guard let value else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) { return date }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: value) { return date }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mmZZZZZ"
        return formatter.date(from: value)
    }
}

@MainActor
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var unreadCount = 0
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        refreshAuthorization()
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] _, _ in
            Task { @MainActor in self?.refreshAuthorization() }
        }
    }

    func refreshAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in self?.authorizationStatus = settings.authorizationStatus }
        }
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] notifications in
            Task { @MainActor in self?.unreadCount = notifications.count }
        }
    }

    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "TripFlow"
        content.body = "Le notifiche di viaggio sono attive."
        content.sound = .default
        content.badge = 1
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
            )
        )
    }

    func markAllRead() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0)
        unreadCount = 0
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        await MainActor.run { self.unreadCount += 1 }
        return [.banner, .sound, .badge]
    }
}
