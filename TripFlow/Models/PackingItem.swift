import Foundation

struct PackingItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var category: PackingCategory
    var isPacked: Bool = false
}

enum PackingCategory: String, CaseIterable, Identifiable {
    case documents = "Documenti"
    case clothes = "Abbigliamento"
    case electronics = "Elettronica"
    case personal = "Personale"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .documents: return "doc.text.fill"
        case .clothes: return "tshirt.fill"
        case .electronics: return "cable.connector"
        case .personal: return "cross.case.fill"
        }
    }
}
