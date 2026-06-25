import SwiftUI

struct ApiKeySetupView: View {
    @State private var keyInput = ""
    @State private var isShowingKey = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Callback para recarregar o estado do app
    var onSaveSuccess: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Ícone e cabeçalho
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "key.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                
                Text("Configuração de API Key")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Para utilizar o Scanner de Recibos IA e o Coach Financeiro, você precisa de uma chave de API gratuita do Google Gemini.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Formulário de Entrada
            VStack(alignment: .leading, spacing: 10) {
                Text("Sua Gemini API Key")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                HStack {
                    if isShowingKey {
                        TextField("Cole sua API Key aqui...", text: $keyInput)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField("Cole sua API Key aqui...", text: $keyInput)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    Button {
                        isShowingKey.toggle()
                    } label: {
                        Image(systemName: isShowingKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(showError ? Color.red : Color.clear, lineWidth: 1)
                )
                
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 24)
            
            // Botões e Ações
            VStack(spacing: 16) {
                Button {
                    saveKey()
                } label: {
                    Text("Salvar e Continuar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [.gray] : [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 24)
                
                Link(destination: URL(string: "https://aistudio.google.com/")!) {
                    HStack {
                        Text("Obter API Key Grátis no Google AI Studio")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func saveKey() {
        let cleanKey = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else { return }
        
        // Simples validação de chave do Gemini (geralmente começam com AIza...)
        if !cleanKey.contains("AIza") && cleanKey.count < 30 {
            errorMessage = "API Key parece inválida. Certifique-se de copiar a chave completa do AI Studio."
            showError = true
            return
        }
        
        let success = KeychainHelper.save(key: "gemini_api_key", value: cleanKey)
        if success {
            onSaveSuccess()
        } else {
            errorMessage = "Erro ao salvar a chave no Keychain de segurança do iOS."
            showError = true
        }
    }
}
