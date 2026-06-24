import Foundation
import Combine

enum PeriodFilter: String, CaseIterable, Identifiable {
    case day = "Hoje"
    case week = "Semana"
    case month = "Mês"
    case all = "Tudo"
    
    var id: String { rawValue }
}

@MainActor
final class ExpenseListViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showError = false
    @Published var analysisResult: ReceiptAnalysis? = nil
    
    @Published var selectedPeriod: PeriodFilter = .all
    @Published var selectedCategory: ExpenseCategory? = nil
    
    let repository: ExpenseRepository
    private let geminiService: GeminiServiceProtocol
    
    var expensesFilteredByPeriod: [Expense] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        return expenses.filter { expense in
            let expenseStartOfDay = calendar.startOfDay(for: expense.date)
            switch selectedPeriod {
            case .day:
                return expenseStartOfDay == startOfToday
            case .week:
                guard let startOfWeek = calendar.date(byAdding: .day, value: -6, to: startOfToday) else { return true }
                return expenseStartOfDay >= startOfWeek && expenseStartOfDay <= startOfToday
            case .month:
                guard let startOfMonth = calendar.date(byAdding: .day, value: -29, to: startOfToday) else { return true }
                return expenseStartOfDay >= startOfMonth && expenseStartOfDay <= startOfToday
            case .all:
                return true
            }
        }
    }
    
    var filteredExpenses: [Expense] {
        expensesFilteredByPeriod.filter { expense in
            if let category = selectedCategory {
                return expense.expenseCategory == category
            }
            return true
        }
    }
    
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
