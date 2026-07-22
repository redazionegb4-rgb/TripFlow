import Foundation
import CoreLocation
import UserNotifications

@MainActor
final class LiveDataStore: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var city = "Posizione attuale"
    @Published var temperature: Double?
    @Published var weatherCode: Int?
    @Published var euroToUSD: Double?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refresh() {
        errorMessage = nil
        isLoading = true
        Task { await fetchExchangeRate() }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        default:
            isLoading = false
            errorMessage = "Attiva la posizione nelle impostazioni di iPhone."
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
            async let place: Void = reverseGeocode(location)
            async let weather: Void = fetchWeather(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            _ = await (place, weather)
            isLoading = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        errorMessage = "Posizione non disponibile."
    }

    private func reverseGeocode(_ location: CLLocation) async {
        do {
            let marks = try await CLGeocoder().reverseGeocodeLocation(location)
            city = marks.first?.locality ?? marks.first?.administrativeArea ?? "Posizione attuale"
        } catch { }
    }

    private func fetchWeather(latitude: Double, longitude: Double) async {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,weather_code&timezone=auto"
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            temperature = response.current.temperature2m
            weatherCode = response.current.weatherCode
        } catch {
            errorMessage = "Impossibile aggiornare il meteo."
        }
    }

    private func fetchExchangeRate() async {
        guard let url = URL(string: "https://api.frankfurter.app/latest?from=EUR&to=USD") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ExchangeResponse.self, from: data)
            euroToUSD = response.rates["USD"]
        } catch {
            errorMessage = "Impossibile aggiornare il cambio valuta."
        }
    }

    var weatherSymbol: String {
        guard let code = weatherCode else { return "cloud.fill" }
        switch code {
        case 0: return "sun.max.fill"
        case 1...3: return "cloud.sun.fill"
        case 45...48: return "cloud.fog.fill"
        case 51...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85...86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

private struct OpenMeteoResponse: Decodable {
    let current: Current
    struct Current: Decodable {
        let temperature2m: Double
        let weatherCode: Int
        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
        }
    }
}

private struct ExchangeResponse: Decodable { let rates: [String: Double] }

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
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false))
        UNUserNotificationCenter.current().add(request)
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
