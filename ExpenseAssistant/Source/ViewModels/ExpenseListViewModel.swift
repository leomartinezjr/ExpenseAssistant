import Foundation
import Combine

@MainActor
final class ExpenseListViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showError = false
    @Published var analysisResult: ReceiptAnalysis? = nil
    
    private let repository: ExpenseRepository
    private let geminiService: GeminiServiceProtocol
    
    init(repository: ExpenseRepository, geminiService: GeminiServiceProtocol = GeminiService()) {
        self.repository = repository
        self.geminiService = geminiService
    }
    
    func loadExpenses() {
        do {
            expenses = try repository.fetchExpenses()
        } catch {
            show(error: "Falha ao carregar despesas: \(error.localizedDescription)")
        }
    }
    
    func addExpense(storeName: String, totalAmount: Double, category: ExpenseCategory, date: Date, rawText: String? = nil) {
        let expense = Expense(
            storeName: storeName.trimmingCharacters(in: .whitespacesAndNewlines),
            totalAmount: totalAmount,
            category: category,
            date: date,
            rawText: rawText
        )
        
        do {
            try repository.addExpense(expense)
            loadExpenses()
        } catch {
            show(error: "Erro ao salvar despesa: \(error.localizedDescription)")
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        do {
            try repository.deleteExpense(expense)
            loadExpenses()
        } catch {
            show(error: "Erro ao deletar despesa: \(error.localizedDescription)")
        }
    }
    
    func analyzeReceipt(text: String?, imageData: Data?, mimeType: String?) async {
        isLoading = true
        errorMessage = nil
        analysisResult = nil
        
        do {
            let result = try await geminiService.analyzeReceipt(text: text, imageData: imageData, mimeType: mimeType)
            analysisResult = result
        } catch {
            show(error: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func confirmAnalysis(rawText: String? = nil) {
        guard let result = analysisResult else { return }
        
        addExpense(
            storeName: result.storeName,
            totalAmount: result.totalAmount,
            category: result.expenseCategory,
            date: result.parsedDate,
            rawText: rawText
        )
        
        analysisResult = nil
    }
    
    func clearAnalysis() {
        analysisResult = nil
    }
    
    private func show(error: String) {
        self.errorMessage = error
        self.showError = true
    }
}
