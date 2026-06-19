import Foundation

struct ReceiptAnalysis: Decodable {
    let storeName: String
    let totalAmount: Double
    let category: String // Alimentação, Transporte, Lazer, Saúde, Outros
    let date: String // Formato YYYY-MM-DD esperado da IA
    
    var parsedDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: date) ?? Date()
    }
    
    var expenseCategory: ExpenseCategory {
        ExpenseCategory.from(stringValue: category)
    }
}
