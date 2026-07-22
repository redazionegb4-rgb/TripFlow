import SwiftUI

struct PackingView: View {
    @State private var items: [PackingItem] = [
        .init(title: "Passaporto", category: .documents, isPacked: true),
        .init(title: "Carta d'imbarco", category: .documents),
        .init(title: "6 magliette", category: .clothes, isPacked: true),
        .init(title: "2 pantaloni", category: .clothes),
        .init(title: "Caricatore iPhone", category: .electronics, isPacked: true),
        .init(title: "Power bank", category: .electronics),
        .init(title: "Farmaci personali", category: .personal)
    ]
    @State private var newItem = ""

    var body: some View {
        List {
            Section {
                ProgressView(value: progress)
                Text("\(packedCount) di \(items.count) elementi pronti")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(PackingCategory.allCases) { category in
                Section {
                    ForEach(items.indices.filter { items[$0].category == category }, id: \.self) { index in
                        Button {
                            items[index].isPacked.toggle()
                        } label: {
                            HStack {
                                Image(systemName: items[index].isPacked ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(items[index].isPacked ? .green : .secondary)
                                Text(items[index].title)
                                    .strikethrough(items[index].isPacked)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let matching = items.indices.filter { items[$0].category == category }
                        for offset in offsets.sorted(by: >) { items.remove(at: matching[offset]) }
                    }
                } header: {
                    Label(category.rawValue, systemImage: category.symbol)
                }
            }

            Section("Aggiungi") {
                HStack {
                    TextField("Nuovo elemento", text: $newItem)
                    Button("Aggiungi") {
                        guard !newItem.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        items.append(.init(title: newItem, category: .personal))
                        newItem = ""
                    }
                }
            }
        }
        .navigationTitle("La mia valigia")
    }

    private var packedCount: Int { items.filter(\.isPacked).count }
    private var progress: Double { items.isEmpty ? 0 : Double(packedCount) / Double(items.count) }
}
