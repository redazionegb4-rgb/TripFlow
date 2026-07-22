import SwiftUI

struct PackingView: View {
    @State private var items: [PackingItem] = [
        .init(title: "Passaporto", category: .essentials, isPacked: true),
        .init(title: "Carta d'imbarco", category: .essentials),
        .init(title: "Adattatore USA", category: .electronics),
        .init(title: "Caricatore iPhone", category: .electronics, isPacked: true),
        .init(title: "Magliette", category: .clothes, isPacked: true),
        .init(title: "Farmaci personali", category: .personal)
    ]
    @State private var showingAdd = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Valigia pronta")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                    }
                    ProgressView(value: progress).tint(AppTheme.accent)
                    Text("\(packedCount) di \(items.count) elementi completati")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            ForEach(PackingCategory.allCases) { category in
                Section {
                    ForEach(items.indices.filter { items[$0].category == category }, id: \.self) { index in
                        Button {
                            items[index].isPacked.toggle()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: items[index].isPacked ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(items[index].isPacked ? AppTheme.accent : .secondary)
                                Text(items[index].title)
                                    .foregroundStyle(.primary)
                                    .strikethrough(items[index].isPacked)
                                Spacer()
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
        }
        .navigationTitle("La mia valigia")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) { AddPackingItemView(items: $items) }
    }

    private var packedCount: Int { items.filter(\.isPacked).count }
    private var progress: Double { items.isEmpty ? 0 : Double(packedCount) / Double(items.count) }
}

private struct AddPackingItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var items: [PackingItem]
    @State private var title = ""
    @State private var category: PackingCategory = .essentials

    var body: some View {
        NavigationStack {
            Form {
                TextField("Elemento", text: $title)
                Picker("Categoria", selection: $category) {
                    ForEach(PackingCategory.allCases) { Text($0.rawValue).tag($0) }
                }
            }
            .navigationTitle("Nuovo elemento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aggiungi") {
                        items.append(.init(title: title, category: category))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
