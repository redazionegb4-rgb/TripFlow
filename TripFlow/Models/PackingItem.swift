import Foundation

struct PackingItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var category: PackingCategory
    var isPacked = false
}

enum PackingCategory: String, CaseIterable, Identifiable, Codable {
    case essentials = "Essenziali"
    case clothes = "Abbigliamento"
    case electronics = "Tecnologia"
    case personal = "Cura personale"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .essentials: return "star.fill"
        case .clothes: return "tshirt.fill"
        case .electronics: return "iphone.gen3"
        case .personal: return "cross.case.fill"
        }
    }
}
