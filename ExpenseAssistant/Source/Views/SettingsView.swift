import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("isBiometricLockEnabled") private var isBiometricLockEnabled = false
    @State private var apiKeyInput = ""
    @State private var hasKeyInKeychain = false
    @State private var isShowingKeyInput = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Segurança")) {
                    Toggle(isOn: $isBiometricLockEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bloqueio do App")
                                Text("Exigir biometria ou código ao abrir")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "faceid")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Chave de API (Gemini)")) {
                    HStack {
                        Label("Status da Chave", systemImage: "key.fill")
                            .foregroundColor(.purple)
                        Spacer()
                        Text(hasKeyInKeychain ? "Configurada no Keychain" : "Não cadastrada")
                            .font(.subheadline)
                            .foregroundColor(hasKeyInKeychain ? .green : .red)
                            .fontWeight(.semibold)
                    }
                    
                    if isShowingKeyInput {
                        VStack(alignment: .leading, spacing: 8) {
                            SecureField("Cole sua nova API Key", text: $apiKeyInput)
                                .font(.system(.body, design: .monospaced))
                                .padding(10)
                                .background(Color(.systemGroupedBackground))
                                .cornerRadius(8)
                            
                            HStack {
                                Button("Salvar Nova Chave") {
                                    saveNewKey()
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                
                                Spacer()
                                
                                Button("Cancelar") {
                                    isShowingKeyInput = false
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button(hasKeyInKeychain ? "Alterar API Key" : "Cadastrar API Key") {
                            isShowingKeyInput = true
                        }
                    }
                    
                    if hasKeyInKeychain {
                        Button("Remover API Key do Keychain", role: .destructive) {
                            removeKey()
                        }
                    }
                }
                
                Section(header: Text("Sobre o App")) {
                    HStack {
                        Text("Versão")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("ExpenseAssistant utiliza inteligência artificial generativa segura (Gemini) e persistência local criptografada para ajudar você a cuidar das suas despesas com segurança máxima.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                checkKeyStatus()
            }
        }
    }
    
    private func checkKeyStatus() {
        if let key = KeychainHelper.read(key: "gemini_api_key"), !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            hasKeyInKeychain = true
        } else {
            hasKeyInKeychain = false
        }
    }
    
    private func saveNewKey() {
        let cleanKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else { return }
        
        let success = KeychainHelper.save(key: "gemini_api_key", value: cleanKey)
        if success {
            apiKeyInput = ""
            isShowingKeyInput = false
            checkKeyStatus()
        }
    }
    
    private func removeKey() {
        KeychainHelper.delete(key: "gemini_api_key")
        checkKeyStatus()
    }
}

#Preview {
    SettingsView()
}
