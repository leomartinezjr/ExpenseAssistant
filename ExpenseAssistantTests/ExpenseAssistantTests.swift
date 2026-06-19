import Testing
import Foundation
import SwiftData
@testable import ExpenseAssistant

// MARK: - Mocks

@MainActor
final class MockExpenseRepository: ExpenseRepository {
    var expenses: [Expense] = []
    var shouldFail = false
    
    func fetchExpenses() throws -> [Expense] {
        if shouldFail { throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Erro simulado"]) }
        return expenses
    }
    
    func addExpense(_ expense: Expense) throws {
        if shouldFail { throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Erro simulado"]) }
        expenses.append(expense)
    }
    
    func deleteExpense(_ expense: Expense) throws {
        if shouldFail { throw NSError(domain: "Test", code: 3, userInfo: [NSLocalizedDescriptionKey: "Erro simulado"]) }
        expenses.removeAll { $0.id == expense.id }
    }
}

final class MockGeminiService: GeminiServiceProtocol, @unchecked Sendable {
    var mockResult: ReceiptAnalysis?
    var mockError: Error?
    
    func analyzeReceipt(text: String?, imageData: Data?, mimeType: String?) async throws -> ReceiptAnalysis {
        if let error = mockError {
            throw error
        }
        if let result = mockResult {
            return result
        }
        throw GeminiError.emptyResponse
    }
}

// MARK: - Testes Unitários

@Suite struct ExpenseAssistantTests {
    
    @Test @MainActor func testLoadExpensesSuccess() async throws {
        let repo = MockExpenseRepository()
        let vm = ExpenseListViewModel(repository: repo)
        
        let expense = Expense(storeName: "Loja Teste", totalAmount: 10.0, category: .others, date: Date())
        repo.expenses = [expense]
        
        vm.loadExpenses()
        
        #expect(vm.expenses.count == 1)
        #expect(vm.expenses.first?.storeName == "Loja Teste")
        #expect(!vm.showError)
    }
    
    @Test @MainActor func testLoadExpensesFailure() async throws {
        let repo = MockExpenseRepository()
        repo.shouldFail = true
        let vm = ExpenseListViewModel(repository: repo)
        
        vm.loadExpenses()
        
        #expect(vm.expenses.isEmpty)
        #expect(vm.showError)
        #expect(vm.errorMessage == "Falha ao carregar despesas: Erro simulado")
    }
    
    @Test @MainActor func testAddExpenseSuccess() async throws {
        let repo = MockExpenseRepository()
        let vm = ExpenseListViewModel(repository: repo)
        
        vm.addExpense(storeName: "McDonalds", totalAmount: 45.90, category: .food, date: Date())
        
        #expect(repo.expenses.count == 1)
        #expect(repo.expenses.first?.storeName == "McDonalds")
        #expect(repo.expenses.first?.totalAmount == 45.90)
        #expect(repo.expenses.first?.expenseCategory == .food)
    }
    
    @Test @MainActor func testDeleteExpenseSuccess() async throws {
        let repo = MockExpenseRepository()
        let vm = ExpenseListViewModel(repository: repo)
        
        let expense = Expense(storeName: "Uber", totalAmount: 25.00, category: .transport, date: Date())
        repo.expenses = [expense]
        vm.expenses = [expense]
        
        vm.deleteExpense(expense)
        
        #expect(repo.expenses.isEmpty)
        #expect(vm.expenses.isEmpty)
    }
    
    @Test @MainActor func testAnalyzeReceiptSuccess() async throws {
        let repo = MockExpenseRepository()
        let gemini = MockGeminiService()
        let vm = ExpenseListViewModel(repository: repo, geminiService: gemini)
        
        gemini.mockResult = ReceiptAnalysis(
            storeName: "Posto Shell",
            totalAmount: 150.00,
            category: "Transporte",
            date: "2026-06-18"
        )
        
        await vm.analyzeReceipt(text: "Abasteci 150 no posto", imageData: nil, mimeType: nil)
        
        #expect(vm.analysisResult != nil)
        #expect(vm.analysisResult?.storeName == "Posto Shell")
        #expect(vm.analysisResult?.totalAmount == 150.00)
        #expect(vm.analysisResult?.expenseCategory == .transport)
        #expect(!vm.isLoading)
        #expect(vm.errorMessage == nil)
        
        // Confirmar análise
        vm.confirmAnalysis(rawText: "Abasteci 150 no posto")
        
        #expect(vm.analysisResult == nil)
        #expect(repo.expenses.count == 1)
        #expect(repo.expenses.first?.storeName == "Posto Shell")
        #expect(repo.expenses.first?.totalAmount == 150.00)
        #expect(repo.expenses.first?.rawText == "Abasteci 150 no posto")
    }
    
    @Test @MainActor func testAnalyzeReceiptFailure() async throws {
        let repo = MockExpenseRepository()
        let gemini = MockGeminiService()
        let vm = ExpenseListViewModel(repository: repo, geminiService: gemini)
        
        gemini.mockError = GeminiError.apiError("Quota Exceeded")
        
        await vm.analyzeReceipt(text: "gasto", imageData: nil, mimeType: nil)
        
        #expect(vm.analysisResult == nil)
        #expect(vm.showError)
        #expect(vm.errorMessage == "Erro retornado pela API do Gemini: Quota Exceeded")
    }
    
    @Test func testDateParsing() {
        let analysis = ReceiptAnalysis(
            storeName: "Teste",
            totalAmount: 5.0,
            category: "Outros",
            date: "2026-06-18"
        )
        
        let date = analysis.parsedDate
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        #expect(calendar.component(.year, from: date) == 2026)
        #expect(calendar.component(.month, from: date) == 6)
        #expect(calendar.component(.day, from: date) == 18)
    }
    
    @Test func testCategoryParsing() {
        #expect(ExpenseCategory.from(stringValue: "Alimentação") == .food)
        #expect(ExpenseCategory.from(stringValue: "Transporte") == .transport)
        #expect(ExpenseCategory.from(stringValue: "Lazer") == .leisure)
        #expect(ExpenseCategory.from(stringValue: "Saúde") == .health)
        #expect(ExpenseCategory.from(stringValue: "Outros") == .others)
        #expect(ExpenseCategory.from(stringValue: "Qualquer Coisa") == .others)
    }
}
