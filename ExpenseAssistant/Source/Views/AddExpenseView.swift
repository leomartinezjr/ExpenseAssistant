import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ExpenseListViewModel
    
    @State private var storeName = ""
    @State private var amountString = ""
    @State private var category: ExpenseCategory = .food
    @State private var date = Date()
    
    private var isFormValid: Bool {
        !storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (Double(amountString) ?? 0.0) > 0.0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Form {
                        Section("Detalhes da Despesa") {
                            TextField("Nome do Estabelecimento", text: $storeName)
                                .textInputAutocapitalization(.words)
                            
                            HStack {
                                Text("R$")
                                    .foregroundColor(.secondary)
                                    .fontWeight(.bold)
                                TextField("0,00", text: $amountString)
                                    .keyboardType(.decimalPad)
                            }
                        }
                        
                        Section("Classificação") {
                            Picker("Categoria", selection: $category) {
                                ForEach(ExpenseCategory.allCases) { category in
                                    HStack {
                                        Image(systemName: category.iconName)
                                            .foregroundColor(category.color)
                                        Text(category.rawValue)
                                    }
                                    .tag(category)
                                }
                            }
                            
                            DatePicker("Data", selection: $date, displayedComponents: .date)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    
                    // Botão Salvar Premium
                    Button(action: saveExpense) {
                        Text("Salvar Despesa")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: isFormValid ? [.blue, .purple] : [.gray, .secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: isFormValid ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isFormValid)
                    .padding()
                }
            }
            .navigationTitle("Nova Despesa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveExpense() {
        guard let amount = Double(amountString.replacingOccurrences(of: ",", with: ".")) else { return }
        viewModel.addExpense(
            storeName: storeName,
            totalAmount: amount,
            category: category,
            date: date
        )
        dismiss()
    }
}

#Preview {
    AddExpenseView(viewModel: {
        let container = try! ModelContainer(for: Expense.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repo = SwiftDataExpenseRepository(context: ModelContext(container))
        return ExpenseListViewModel(repository: repo)
    }())
}
