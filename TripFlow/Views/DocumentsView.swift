import SwiftUI
import LocalAuthentication

struct DocumentsView: View {
    @State private var unlocked = false
    @State private var message = ""
    var body: some View {
        Group {
            if unlocked { content }
            else { VStack(spacing:18){Image(systemName:"faceid").font(.system(size:64)).foregroundStyle(AppTheme.accent);Text("Documenti protetti").font(.title2.bold());Text("Usa Face ID, Touch ID o il codice dell’iPhone per accedere.").multilineTextAlignment(.center).foregroundStyle(.secondary);Button("Sblocca documenti"){authenticate()}.buttonStyle(.borderedProminent);if !message.isEmpty{Text(message).font(.caption).foregroundStyle(.red)}}.padding(30) }
        }.navigationTitle("Documenti").toolbar{if unlocked{ToolbarItem(placement:.topBarTrailing){Button{unlocked=false}label:{Image(systemName:"lock.fill")}}}}
    }
    private var content: some View { List { Section("Documenti"){doc("Passaporto","person.text.rectangle.fill");doc("Assicurazione viaggio","shield.checkered");doc("Prenotazione hotel","bed.double.fill")};Section{Button{ }label:{Label("Aggiungi documento",systemImage:"plus")}} }.listStyle(.insetGrouped) }
    private func doc(_ title:String,_ icon:String)->some View{HStack{Image(systemName:icon).foregroundStyle(AppTheme.accent).frame(width:30);Text(title);Spacer();Image(systemName:"chevron.right").foregroundStyle(.secondary)}}
    private func authenticate(){let context=LAContext();var error:NSError?;guard context.canEvaluatePolicy(.deviceOwnerAuthentication,error:&error)else{message="Face ID o codice non disponibili su questo dispositivo.";return};context.evaluatePolicy(.deviceOwnerAuthentication,localizedReason:"Accedi ai documenti di viaggio"){success,_ in DispatchQueue.main.async{if success{unlocked=true;message=""}else{message="Autenticazione non riuscita."}}}}
}
