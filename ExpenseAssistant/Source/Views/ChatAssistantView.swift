import SwiftUI

struct ChatAssistantView: View {
    @StateObject var viewModel: ChatAssistantViewModel
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    init(repository: ExpenseRepository) {
        _viewModel = StateObject(wrappedValue: ChatAssistantViewModel(repository: repository))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Histórico de mensagens
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            typingIndicator
                                .id("typingIndicator")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    scrollToLastMessage(with: proxy)
                }
                .onChange(of: viewModel.isLoading) { _ in
                    scrollToLastMessage(with: proxy)
                }
            }
            
            Divider()
            
            // Barra de entrada
            inputBar
        }
        .navigationTitle("IA Coach Financeiro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.clearChat()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // Balão de Mensagem
    private func messageBubble(_ message: ChatMessage) -> some View {
        let isUser = message.sender == .user
        return HStack {
            if isUser { Spacer() }
            
            Text(message.content)
                .font(.system(.body, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundColor(isUser ? .white : .primary)
                .background(
                    Group {
                        if isUser {
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color(.secondarySystemGroupedBackground)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(isUser ? 0.1 : 0.02), radius: 3, x: 0, y: 1)
                .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
            
            if !isUser { Spacer() }
        }
    }
    
    // Indicador de digitação animado
    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(viewModel.isLoading ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(0), value: viewModel.isLoading)
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(viewModel.isLoading ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(0.2), value: viewModel.isLoading)
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(viewModel.isLoading ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(0.4), value: viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            Spacer()
        }
        .frame(maxWidth: 280, alignment: .leading)
    }
    
    // Barra de entrada inferior
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Pergunte ao Coach...", text: $inputText)
                .font(.system(.body, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(20)
                .focused($isInputFocused)
                .disabled(viewModel.isLoading)
            
            Button {
                let text = inputText
                inputText = ""
                Task {
                    await viewModel.sendMessage(text)
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .font(.body)
                    .padding(10)
                    .background(
                        LinearGradient(
                            colors: inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [.gray] : [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func scrollToLastMessage(with proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring()) {
                if viewModel.isLoading {
                    proxy.scrollTo("typingIndicator", anchor: .bottom)
                } else if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
}
