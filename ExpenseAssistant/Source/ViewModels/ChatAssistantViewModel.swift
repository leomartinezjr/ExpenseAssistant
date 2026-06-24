import Foundation
import Combine

@MainActor
final class ChatAssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showError = false
    
    private let repository: ExpenseRepository
    private let geminiService: GeminiServiceProtocol
    
    init(repository: ExpenseRepository, geminiService: GeminiServiceProtocol = GeminiService()) {
        self.repository = repository
        self.geminiService = geminiService
        
        // Mensagem de boas-vindas inicial do coach
        self.messages = [
            ChatMessage(
                sender: .assistant,
                content: "Olá! Sou seu Coach Financeiro Inteligente. Posso analisar seus gastos reais e te dar dicas para economizar. Pergunte-me algo como 'Qual foi meu maior gasto?' ou 'Como posso economizar?'"
            )
        ]
    }
    
    func sendMessage(_ content: String) async {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        // 1. Adicionar mensagem do usuário
        let userMessage = ChatMessage(sender: .user, content: trimmedContent)
        messages.append(userMessage)
        
        isLoading = true
        errorMessage = nil
        
        // 2. Buscar despesas atuais do banco local e mapear para DTOs (Sendable)
        let expenses: [Expense]
        do {
            expenses = try repository.fetchExpenses()
        } catch {
            expenses = []
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dtos = expenses.map { expense in
            ExpenseDTO(
                title: expense.storeName,
                amount: expense.totalAmount,
                category: expense.category,
                date: formatter.string(from: expense.date)
            )
        }
        
        // 3. Chamar a API do Gemini com o histórico de conversas
        let history = Array(messages.dropLast())
        
        do {
            let aiResponse = try await geminiService.sendChatMessage(
                history: history,
                currentExpenses: dtos,
                newPrompt: trimmedContent
            )
            
            // 4. Adicionar resposta do assistente
            let assistantMessage = ChatMessage(sender: .assistant, content: aiResponse)
            messages.append(assistantMessage)
        } catch {
            self.errorMessage = "Falha ao obter resposta: \(error.localizedDescription)"
            self.showError = true
            
            // Adiciona mensagem de erro no chat para guiar o usuário
            let errorMsg = ChatMessage(
                sender: .assistant,
                content: "Ops! Ocorreu um problema ao conectar com o serviço de IA. Verifique sua conexão e sua chave de API do Gemini."
            )
            messages.append(errorMsg)
        }
        
        isLoading = false
    }
    
    func clearChat() {
        messages = [
            ChatMessage(
                sender: .assistant,
                content: "Conversa reiniciada! Como posso te ajudar com suas finanças hoje?"
            )
        ]
    }
}
