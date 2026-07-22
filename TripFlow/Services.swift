import Foundation
import CoreLocation
import UserNotifications

@MainActor
final class TripStore: ObservableObject {
    @Published var flights: [Flight] { didSet { save() } }
    private let key = "tripflow.flights.v4"
    init() {
        if let data = UserDefaults.standard.data(forKey: key), let saved = try? JSONDecoder().decode([Flight].self, from: data) { flights = saved }
        else { flights = [Flight.demo] }
    }
    var nextFlight: Flight? { flights.filter { $0.departure > Date() }.sorted { $0.departure < $1.departure }.first ?? flights.first }
    func add(_ flight: Flight) { flights.append(flight) }
    func delete(at offsets: IndexSet) { flights.remove(atOffsets: offsets) }
    func delete(_ flight: Flight) { flights.removeAll { $0.id == flight.id } }
    private func save() { if let data = try? JSONEncoder().encode(flights) { UserDefaults.standard.set(data, forKey: key) } }
}

struct WeatherSnapshot: Equatable { let city: String; let temperature: Double; let code: Int; let minimum: Double?; let maximum: Double? }

@MainActor
final class LiveDataStore: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentWeather: WeatherSnapshot?
    @Published var destinationWeather: WeatherSnapshot?
    @Published var rates: [String: Double] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let locationManager = CLLocationManager()

    override init() { super.init(); locationManager.delegate = self; locationManager.desiredAccuracy = kCLLocationAccuracyKilometer }

    func refresh(destination: String? = nil) {
        errorMessage = nil; isLoading = true
        Task { await fetchRates(); if let destination, !destination.isEmpty { await fetchDestinationWeather(city: destination) } }
        switch locationManager.authorizationStatus {
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: locationManager.requestLocation()
        default: isLoading = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse { manager.requestLocation() } }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { guard let location = locations.last else { return }; Task { await fetchCurrentWeather(location); isLoading = false } }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { isLoading = false; errorMessage = "Posizione non disponibile." }

    private func fetchCurrentWeather(_ location: CLLocation) async {
        let name = (try? await CLGeocoder().reverseGeocodeLocation(location).first?.locality) ?? "Posizione attuale"
        currentWeather = await weather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, city: name)
    }

    func fetchDestinationWeather(city: String) async {
        guard let encoded = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=1&language=it&format=json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(GeoResponse.self, from: data).results?.first
            if let result { destinationWeather = await weather(latitude: result.latitude, longitude: result.longitude, city: result.name) }
            else { errorMessage = "Città di destinazione non trovata." }
        } catch { errorMessage = "Impossibile aggiornare il meteo della destinazione." }
    }

    private func weather(latitude: Double, longitude: Double, city: String) async -> WeatherSnapshot? {
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min&forecast_days=1&timezone=auto") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url); let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            return WeatherSnapshot(city: city, temperature: response.current.temperature2m, code: response.current.weatherCode, minimum: response.daily?.temperature2mMin.first, maximum: response.daily?.temperature2mMax.first)
        } catch { return nil }
    }

    private func fetchRates() async {
        guard let url = URL(string: "https://api.frankfurter.app/latest?from=EUR") else { return }
        do { let (data, _) = try await URLSession.shared.data(from: url); rates = try JSONDecoder().decode(ExchangeResponse.self, from: data).rates } catch { errorMessage = "Impossibile aggiornare i cambi valuta." }
    }

    func convert(_ amount: Double, from: String, to: String) -> Double? {
        if from == to { return amount }
        let inEUR = from == "EUR" ? amount : (rates[from].map { amount / $0 })
        guard let inEUR else { return nil }
        return to == "EUR" ? inEUR : rates[to].map { inEUR * $0 }
    }

    func symbol(for code: Int?) -> String { guard let code else { return "cloud.fill" }; switch code { case 0: return "sun.max.fill"; case 1...3: return "cloud.sun.fill"; case 45...48: return "cloud.fog.fill"; case 51...67,80...82: return "cloud.rain.fill"; case 71...77,85...86: return "cloud.snow.fill"; case 95...99: return "cloud.bolt.rain.fill"; default: return "cloud.fill" } }
}

private struct OpenMeteoResponse: Decodable {
    let current: Current; let daily: Daily?
    struct Current: Decodable { let temperature2m: Double; let weatherCode: Int; enum CodingKeys: String, CodingKey { case temperature2m = "temperature_2m"; case weatherCode = "weather_code" } }
    struct Daily: Decodable { let temperature2mMax: [Double]; let temperature2mMin: [Double]; enum CodingKeys: String, CodingKey { case temperature2mMax = "temperature_2m_max"; case temperature2mMin = "temperature_2m_min" } }
}
private struct GeoResponse: Decodable { let results: [Place]?; struct Place: Decodable { let name: String; let latitude: Double; let longitude: Double } }
private struct ExchangeResponse: Decodable { let rates: [String: Double] }

@MainActor
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var unreadCount = 0; @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    override init() { super.init(); UNUserNotificationCenter.current().delegate = self; refreshAuthorization() }
    func requestPermission() { UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { [weak self] _,_ in Task { @MainActor in self?.refreshAuthorization() } } }
    func refreshAuthorization() { UNUserNotificationCenter.current().getNotificationSettings { [weak self] s in Task { @MainActor in self?.authorizationStatus = s.authorizationStatus } }; UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] n in Task { @MainActor in self?.unreadCount = n.count } } }
    func scheduleTestNotification() { let c = UNMutableNotificationContent(); c.title = "TripFlow"; c.body = "Le notifiche di viaggio sono attive."; c.sound = .default; c.badge = 1; UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false))) }
    func markAllRead() { UNUserNotificationCenter.current().removeAllDeliveredNotifications(); UNUserNotificationCenter.current().setBadgeCount(0); unreadCount = 0 }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions { await MainActor.run { self.unreadCount += 1 }; return [.banner,.sound,.badge] }
}
