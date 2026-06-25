import SwiftUI
import SwiftData

@main
struct ExpenseAssistantApp: App {
    let container: ModelContainer
    let viewModel: ExpenseListViewModel
    
    init() {
        do {
            // Obtém o diretório do App Group compartilhado
            let sharedDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.leomartinez.ExpenseAssistant")
            let databaseURL = sharedDirectory?.appendingPathComponent("default.store")
            
            let config: ModelConfiguration
            if let databaseURL = databaseURL {
                config = ModelConfiguration(url: databaseURL)
                
                // Cria o diretório se não existir
                let directory = databaseURL.deletingLastPathComponent()
                try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                
                // Habilita a criptografia nativa do iOS no arquivo do banco de dados quando bloqueado
                let attributes: [FileAttributeKey: Any] = [.protectionKey: FileProtectionType.complete]
                try? FileManager.default.setAttributes(attributes, ofItemAtPath: databaseURL.path)
            } else {
                config = ModelConfiguration()
            }
            
            // Inicializa o contêiner do SwiftData usando a configuração do App Group
            container = try ModelContainer(for: Expense.self, configurations: config)
            
            // Instancia o contexto no MainActor
            let context = ModelContext(container)
            let repository = SwiftDataExpenseRepository(context: context)
            
            // Cria a ViewModel injetando o repositório
            viewModel = ExpenseListViewModel(repository: repository)
        } catch {
            fatalError("Não foi possível inicializar o contêiner do SwiftData: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            BiometricLockView(content: ExpenseListView(viewModel: viewModel))
        }
        .modelContainer(container)
    }
}
