import SwiftUI
import Charts
import SwiftData

struct CategoryTotal: Identifiable {
    let category: ExpenseCategory
    let amount: Double
    var id: String { category.rawValue }
}

struct ExpenseListView: View {
    @StateObject var viewModel: ExpenseListViewModel
    
    @State private var showingAddExpense = false
    @State private var showingScanReceipt = false
    
    var totalAmount: Double {
        viewModel.expensesFilteredByPeriod.reduce(0.0) { $0 + $1.totalAmount }
    }
    
    var categoryTotals: [CategoryTotal] {
        var totals: [ExpenseCategory: Double] = [:]
        for expense in viewModel.expensesFilteredByPeriod {
            totals[expense.expenseCategory, default: 0.0] += expense.totalAmount
        }
        return totals.map { CategoryTotal(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.expenses.isEmpty {
                    emptyStateView
                } else {
                    dashboardView
                }
            }
            .navigationTitle("Minhas Despesas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink {
                            ChatAssistantView(repository: viewModel.repository)
                        } label: {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                        
                        Button {
                            showingScanReceipt = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Scanner IA")
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(16)
                            .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                        Button {
                            showingAddExpense = true
                        } label: {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingScanReceipt) {
                ScanReceiptView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadExpenses()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 50))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            
            VStack(spacing: 8) {
                Text("Sem despesas ainda")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Registre seus gastos manualmente ou envie uma foto de recibo para a nossa Inteligência Artificial ler.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                Button {
                    showingScanReceipt = true
                } label: {
                    Label("Escanear Recibo com IA", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                        .shadow(color: .purple.opacity(0.2), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal, 40)
                
                Button("Adicionar Manualmente") {
                    showingAddExpense = true
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            }
            .padding(.top, 16)
        }
    }
    
    private var dashboardView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Picker de Período Temporal
                Picker("Período", selection: $viewModel.selectedPeriod) {
                    ForEach(PeriodFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Resumo Financeiro Card
                VStack(spacing: 8) {
                    Text("TOTAL GASTO")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(String(format: "R$ %.2f", totalAmount))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                
                // Gráfico Donut Chart
                if !categoryTotals.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Distribuição por Categoria")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            Chart(categoryTotals) { item in
                                SectorMark(
                                    angle: .value("Gasto", item.amount),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(item.category.color)
                                .opacity(viewModel.selectedCategory == nil || viewModel.selectedCategory == item.category ? 1.0 : 0.3)
                            }
                            .frame(width: 140, height: 140)
                            
                            // Legendas com Porcentagem
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(categoryTotals) { item in
                                    Button {
                                        withAnimation(.spring()) {
                                            if viewModel.selectedCategory == item.category {
                                                viewModel.selectedCategory = nil
                                            } else {
                                                viewModel.selectedCategory = item.category
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(item.category.color)
                                                .frame(width: 8, height: 8)
                                            Text(item.category.rawValue)
                                                .font(.caption)
                                                .foregroundColor(viewModel.selectedCategory == nil || viewModel.selectedCategory == item.category ? .primary : .secondary)
                                                .fontWeight(viewModel.selectedCategory == item.category ? .bold : .regular)
                                            Spacer()
                                            Text(String(format: "R$ %.0f", item.amount))
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                }
                
                // Lista de Transações Recentes
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Lançamentos Recentes")
                            .font(.headline)
                        
                        Spacer()
                        
                        if let selected = viewModel.selectedCategory {
                            Button {
                                withAnimation {
                                    viewModel.selectedCategory = nil
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(selected.rawValue)
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selected.color)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if viewModel.filteredExpenses.isEmpty {
                        Text("Nenhuma despesa para este período ou categoria.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredExpenses) { expense in
                                expenseRow(for: expense)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                viewModel.deleteExpense(expense)
                                            }
                                        } label: {
                                            Label("Excluir", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.vertical)
        }
    }
    
    private func expenseRow(for expense: Expense) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(expense.expenseCategory.color.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: expense.expenseCategory.iconName)
                    .foregroundColor(expense.expenseCategory.color)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.storeName)
                    .font(.body)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    if expense.rawText != nil {
                        Text("•")
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("IA")
                            .foregroundColor(.purple)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "R$ %.2f", expense.totalAmount))
                .font(.body)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ExpenseListView(viewModel: {
        let container = try! ModelContainer(for: Expense.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repo = SwiftDataExpenseRepository(context: ModelContext(container))
        let vm = ExpenseListViewModel(repository: repo)
        vm.expenses = [
            Expense(storeName: "Supermercado Pão de Açúcar", totalAmount: 245.50, category: .food, date: Date()),
            Expense(storeName: "Uber Viagem", totalAmount: 42.90, category: .transport, date: Date()),
            Expense(storeName: "Cinemark", totalAmount: 78.00, category: .leisure, date: Date())
        ]
        return vm
    }())
}
