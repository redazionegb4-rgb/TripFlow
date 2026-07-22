import SwiftUI

struct PackingView: View {
    @AppStorage("packingItemsV2") private var storedItems = ""
    @State private var items: [PackingItem] = []
    @State private var showingAdd = false
    @State private var loaded = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Valigia pronta").font(.headline)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                    }
                    ProgressView(value: progress).tint(AppTheme.accent)
                    Text(items.isEmpty ? "Aggiungi il primo elemento della tua valigia" : "\(packedCount) di \(items.count) elementi completati")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 8)
            }

            if items.isEmpty {
                Section {
                    ContentUnavailableView("Valigia vuota", systemImage: "suitcase", description: Text("Premi + per creare una checklist personale. Non vengono più inseriti dati dimostrativi."))
                }
            } else {
                ForEach(PackingCategory.allCases) { category in
                    let indexes = items.indices.filter { items[$0].category == category }
                    if !indexes.isEmpty {
                        Section {
                            ForEach(indexes, id: \.self) { index in
                                Button {
                                    items[index].isPacked.toggle(); save()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: items[index].isPacked ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(items[index].isPacked ? AppTheme.accent : .secondary)
                                        Text(items[index].title).foregroundStyle(.primary).strikethrough(items[index].isPacked)
                                        Spacer()
                                    }
                                }
                            }
                            .onDelete { offsets in
                                let matching = items.indices.filter { items[$0].category == category }
                                for offset in offsets.sorted(by: >) { items.remove(at: matching[offset]) }
                                save()
                            }
                        } header: { Label(category.rawValue, systemImage: category.symbol) }
                    }
                }
            }
        }
        .navigationTitle("La mia valigia")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button { showingAdd = true } label: { Image(systemName: "plus") } }
        }
        .sheet(isPresented: $showingAdd) { AddPackingItemView { item in items.append(item); save() } }
        .onAppear { loadOnce() }
    }

    private var packedCount: Int { items.filter(\.isPacked).count }
    private var progress: Double { items.isEmpty ? 0 : Double(packedCount) / Double(items.count) }
    private func loadOnce() {
        guard !loaded else { return }; loaded = true
        guard let data = storedItems.data(using: .utf8), let decoded = try? JSONDecoder().decode([PackingItem].self, from: data) else { return }
        items = decoded
    }
    private func save() {
        guard let data = try? JSONEncoder().encode(items), let string = String(data: data, encoding: .utf8) else { return }
        storedItems = string
    }
}

private struct AddPackingItemView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (PackingItem) -> Void
    @State private var title = ""
    @State private var category: PackingCategory = .essentials

    var body: some View {
        NavigationStack {
            Form {
                TextField("Elemento", text: $title)
                Picker("Categoria", selection: $category) { ForEach(PackingCategory.allCases) { Text($0.rawValue).tag($0) } }
            }
            .navigationTitle("Nuovo elemento").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aggiungi") { onAdd(.init(title: title.trimmingCharacters(in: .whitespacesAndNewlines), category: category)); dismiss() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
