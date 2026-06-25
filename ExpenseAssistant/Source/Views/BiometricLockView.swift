import SwiftUI
import LocalAuthentication

struct BiometricLockView<Content: View>: View {
    let content: Content
    
    @AppStorage("isBiometricLockEnabled") private var isBiometricLockEnabled = false
    @State private var isUnlocked = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            if !isBiometricLockEnabled || isUnlocked {
                content
            } else {
                lockScreenView
            }
        }
        .onAppear {
            checkLockState()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if isBiometricLockEnabled {
                if newPhase == .background {
                    isUnlocked = false
                } else if newPhase == .active && !isUnlocked {
                    authenticate()
                }
            }
        }
    }
    
    private var lockScreenView: some View {
        VStack(spacing: 28) {
            Spacer()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                
                Text("ExpenseAssistant Bloqueado")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Autentique-se com biometria ou código do dispositivo para acessar suas despesas.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                authenticate()
            } label: {
                Label("Desbloquear App", systemImage: "faceid")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 220, height: 50)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
                    .shadow(color: .purple.opacity(0.2), radius: 6, x: 0, y: 3)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func checkLockState() {
        if isBiometricLockEnabled {
            authenticate()
        }
    }
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        // Verifica se o dispositivo possui autenticação por biometria ou senha cadastrada
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Desbloqueie o ExpenseAssistant para acessar seus dados."
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        withAnimation {
                            isUnlocked = true
                        }
                    }
                }
            }
        } else {
            // Dispositivo sem autenticação configurada: libera acesso
            isUnlocked = true
        }
    }
}

#Preview {
    BiometricLockView(content: Text("Conteúdo Protegido"))
}
