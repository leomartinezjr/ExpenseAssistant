import Foundation
import SwiftData

@MainActor
protocol ExpenseRepository {
    func fetchExpenses() throws -> [Expense]
    func addExpense(_ expense: Expense) throws
    func deleteExpense(_ expense: Expense) throws
}

@MainActor
final class SwiftDataExpenseRepository: ExpenseRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func fetchExpenses() throws -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(descriptor)
    }
    
    func addExpense(_ expense: Expense) throws {
        context.insert(expense)
        try context.save()
    }
    
    func deleteExpense(_ expense: Expense) throws {
        context.delete(expense)
        try context.save()
    }
}
