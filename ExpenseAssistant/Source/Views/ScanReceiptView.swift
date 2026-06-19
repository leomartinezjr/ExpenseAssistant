import SwiftUI
import PhotosUI
import SwiftData

struct ScanReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ExpenseListViewModel
    
    @State private var inputText = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        textInputCard
                        photoInputCard
                        analyzeButton
                    }
                }
                
                aiConfirmationOverlay
            }
            .navigationTitle("Leitor Inteligente IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
            .alert("Erro de IA", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var textInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Comando de Voz ou Texto")
                    .font(.headline)
            }
            
            Text("Escreva livremente sobre seu gasto (Ex: 'gastei 50 reais de Uber ontem de manhã' ou 'R$ 120 no mercado hoje').")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("O que você comprou e quanto custou?", text: $inputText, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var photoInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.viewfinder")
                    .foregroundColor(.purple)
                    .font(.title3)
                Text("Foto do Recibo / Nota Fiscal")
                    .font(.headline)
            }
            
            Text("Selecione um recibo da sua galeria de fotos para extrair os dados automaticamente.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let selectedImage = selectedImage {
                ZStack {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                    
                    if viewModel.isLoading {
                        LaserScannerView()
                            .frame(maxHeight: 200)
                            .padding(.vertical, 8)
                    }
                }
                
                Button(role: .destructive) {
                    clearImageSelection()
                } label: {
                    Label("Remover Foto", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                        Text("Selecionar Foto do Recibo")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(colors: [.blue.opacity(0.5), .purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [6, 4])
                            )
                    )
                    .background(Color.purple.opacity(0.02))
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                            selectedImage = UIImage(data: data)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var analyzeButton: some View {
        Button(action: runAIAnalysis) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(viewModel.isLoading ? "Processando com IA..." : "Analisar com Gemini")
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: isInputEmpty || viewModel.isLoading ? [.gray, .secondary] : [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: isInputEmpty ? .clear : .purple.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isInputEmpty || viewModel.isLoading)
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
    
    private var aiConfirmationOverlay: some View {
        Group {
            if let analysis = viewModel.analysisResult {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    VStack(spacing: 20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 44))
                            .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .padding(.top)
                        
                        Text("Extração Concluída!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Verifique se as informações identificadas pela IA estão corretas.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Estabelecimento:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(analysis.storeName)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Valor Total:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "R$ %.2f", analysis.totalAmount))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Text("Categoria:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Label(analysis.expenseCategory.rawValue, systemImage: analysis.expenseCategory.iconName)
                                    .foregroundColor(analysis.expenseCategory.color)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Data Identificada:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(analysis.date)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        
                        HStack(spacing: 16) {
                            Button(role: .cancel) {
                                viewModel.clearAnalysis()
                            } label: {
                                Text("Descartar")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                viewModel.confirmAnalysis(rawText: inputText.isEmpty ? "Recibo carregado por imagem" : inputText)
                                dismiss()
                            } label: {
                                Text("Confirmar e Salvar")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(24)
                    .shadow(radius: 20)
                    .padding(.horizontal, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Helpers
    
    private var isInputEmpty: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImageData == nil
    }
    
    private func clearImageSelection() {
        selectedItem = nil
        selectedImageData = nil
        selectedImage = nil
    }
    
    private func runAIAnalysis() {
        Task {
            await viewModel.analyzeReceipt(
                text: inputText,
                imageData: selectedImageData,
                mimeType: "image/jpeg"
            )
        }
    }
}

#Preview {
    ScanReceiptView(viewModel: {
        let container = try! ModelContainer(for: Expense.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let repo = SwiftDataExpenseRepository(context: ModelContext(container))
        return ExpenseListViewModel(repository: repo)
    }())
}

struct LaserScannerView: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Linha de laser brilhante com gradiente
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            colors: [.clear, .blue, .purple, .blue, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 4)
                    .shadow(color: .purple.opacity(0.8), radius: 8, x: 0, y: 0)
                    .shadow(color: .blue.opacity(0.8), radius: 8, x: 0, y: 0)
                    .offset(y: animate ? geometry.size.height - 4 : 0)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                        ) {
                            animate = true
                        }
                    }
            }
        }
    }
}

