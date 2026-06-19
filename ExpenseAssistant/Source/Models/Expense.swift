import Foundation
import SwiftData
import SwiftUI

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case food = "Alimentação"
    case transport = "Transporte"
    case leisure = "Lazer"
    case health = "Saúde"
    case others = "Outros"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .leisure: return "gamecontroller.fill"
        case .health: return "heart.text.square.fill"
        case .others: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return Color(.systemOrange)
        case .transport: return Color(.systemBlue)
        case .leisure: return Color(.systemPurple)
        case .health: return Color(.systemGreen)
        case .others: return Color(.systemGray)
        }
    }
    
    static func from(stringValue: String) -> ExpenseCategory {
        return ExpenseCategory(rawValue: stringValue) ?? .others
    }
}

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var storeName: String
    var totalAmount: Double
    var category: String
    var date: Date
    var rawText: String?
    
    var expenseCategory: ExpenseCategory {
        get {
            ExpenseCategory.from(stringValue: category)
        }
        set {
            category = newValue.rawValue
        }
    }
    
    init(id: UUID = UUID(), storeName: String, totalAmount: Double, category: ExpenseCategory, date: Date, rawText: String? = nil) {
        self.id = id
        self.storeName = storeName
        self.totalAmount = totalAmount
        self.category = category.rawValue
        self.date = date
        self.rawText = rawText
    }
}
