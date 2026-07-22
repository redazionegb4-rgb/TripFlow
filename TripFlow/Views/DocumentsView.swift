import SwiftUI
import LocalAuthentication
import UniformTypeIdentifiers
import QuickLook

private struct SavedTravelDocument: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var fileName: String
    var addedAt = Date()
}

struct DocumentsView: View {
    @AppStorage("travelDocumentsV2") private var storedDocuments = ""
    @State private var documents: [SavedTravelDocument] = []
    @State private var unlocked = false
    @State private var message = ""
    @State private var showingImporter = false
    @State private var previewURL: URL?
    @State private var loaded = false

    var body: some View {
        Group {
            if unlocked { content }
            else {
                VStack(spacing: 18) {
                    Image(systemName: "faceid").font(.system(size: 64)).foregroundStyle(AppTheme.accent)
                    Text("Documenti protetti").font(.title2.bold())
                    Text("Usa Face ID, Touch ID o il codice dell’iPhone per accedere ai tuoi file di viaggio.")
                        .multilineTextAlignment(.center).foregroundStyle(.secondary)
                    Button("Sblocca documenti") { authenticate() }.buttonStyle(.borderedProminent)
                    if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.red) }
                }.padding(30)
            }
        }
        .navigationTitle("Documenti")
        .toolbar {
            if unlocked {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingImporter = true } label: { Image(systemName: "plus") }
                    Button { unlocked = false } label: { Image(systemName: "lock.fill") }
                }
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.pdf, .image, .plainText, .data], allowsMultipleSelection: false) { result in
            importDocument(result)
        }
        .quickLookPreview($previewURL)
        .onAppear { loadOnce() }
    }

    private var content: some View {
        List {
            if documents.isEmpty {
                ContentUnavailableView("Nessun documento", systemImage: "doc.badge.plus", description: Text("Premi + per importare passaporto, biglietti, assicurazioni o prenotazioni. I file restano nel dispositivo."))
            } else {
                Section("I miei documenti") {
                    ForEach(documents) { document in
                        Button { previewURL = documentsFolder.appendingPathComponent(document.fileName) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: icon(for: document.fileName)).foregroundStyle(AppTheme.accent).frame(width: 30)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(document.title).foregroundStyle(.primary)
                                    Text(document.addedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                        }
                    }.onDelete(perform: delete)
                }
                Section { Text("I documenti sono protetti dall’autenticazione del dispositivo e salvati nella cartella privata dell’app.").font(.footnote).foregroundStyle(.secondary) }
            }
        }.listStyle(.insetGrouped)
    }

    private var documentsFolder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("TravelDocuments", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
    private func icon(for name: String) -> String {
        let ext = URL(fileURLWithPath: name).pathExtension.lowercased()
        return ext == "pdf" ? "doc.richtext.fill" : (["jpg","jpeg","png","heic"].contains(ext) ? "photo.fill" : "doc.fill")
    }
    private func loadOnce() {
        guard !loaded else { return }; loaded = true
        guard let data = storedDocuments.data(using: .utf8), let decoded = try? JSONDecoder().decode([SavedTravelDocument].self, from: data) else { return }
        documents = decoded
    }
    private func save() {
        guard let data = try? JSONEncoder().encode(documents), let string = String(data: data, encoding: .utf8) else { return }
        storedDocuments = string
    }
    private func importDocument(_ result: Result<[URL], Error>) {
        do {
            guard let source = try result.get().first else { return }
            let accessed = source.startAccessingSecurityScopedResource(); defer { if accessed { source.stopAccessingSecurityScopedResource() } }
            let safeName = "\(UUID().uuidString)-\(source.lastPathComponent)"
            let destination = documentsFolder.appendingPathComponent(safeName)
            try FileManager.default.copyItem(at: source, to: destination)
            documents.append(.init(title: source.deletingPathExtension().lastPathComponent, fileName: safeName)); save()
        } catch { message = "Impossibile importare il documento: \(error.localizedDescription)" }
    }
    private func delete(_ offsets: IndexSet) {
        for index in offsets { try? FileManager.default.removeItem(at: documentsFolder.appendingPathComponent(documents[index].fileName)) }
        documents.remove(atOffsets: offsets); save()
    }
    private func authenticate() {
        let context = LAContext(); var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { message = "Face ID o codice non disponibili su questo dispositivo."; return }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Accedi ai documenti di viaggio") { success, _ in
            DispatchQueue.main.async { if success { unlocked = true; message = "" } else { message = "Autenticazione non riuscita." } }
        }
    }
}
