import Foundation

struct ExpenseDTO: Sendable, Codable {
    let title: String
    let amount: Double
    let category: String
    let date: String
}

protocol GeminiServiceProtocol: Sendable {
    func analyzeReceipt(text: String?, imageData: Data?, mimeType: String?) async throws -> ReceiptAnalysis
    func sendChatMessage(history: [ChatMessage], currentExpenses: [ExpenseDTO], newPrompt: String) async throws -> String
}

enum GeminiError: Error, LocalizedError {
    case invalidURL
    case missingApiKey
    case emptyResponse
    case parsingError(Error)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "A URL da API do Gemini é inválida."
        case .missingApiKey: return "Chave da API do Gemini não encontrada. Configure-a no arquivo Secrets.xcconfig."
        case .emptyResponse: return "A resposta da IA veio vazia."
        case .parsingError(let err): return "Erro ao decodificar a resposta da IA: \(err.localizedDescription)"
        case .apiError(let msg): return "Erro retornado pela API do Gemini: \(msg)"
        }
    }
}

// Estrutura de resposta da API do Gemini
private struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}

final class GeminiService: GeminiServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    private var apiKey: String {
        // 1. Tentar ler do Keychain de forma segura
        if let key = KeychainHelper.read(key: "gemini_api_key"), !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return key
        }
        
        // 2. Fallback para ler do Bundle (Info.plist) para suporte retrocompatível e migração automática
        let bundleKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
        let cleanBundleKey = bundleKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !cleanBundleKey.isEmpty && cleanBundleKey != "SUA_API_KEY_AQUI" {
            // Migrar automaticamente para o Keychain para segurança
            KeychainHelper.save(key: "gemini_api_key", value: cleanBundleKey)
            return cleanBundleKey
        }
        
        return ""
    }
    
    func analyzeReceipt(text: String?, imageData: Data?, mimeType: String?) async throws -> ReceiptAnalysis {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, key != "SUA_API_KEY_AQUI" else {
            throw GeminiError.missingApiKey
        }
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(key)") else {
            throw GeminiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Montar o corpo da requisição
        var parts: [[String: Any]] = []
        
        // Adiciona prompt de instrução
        let promptText = "Analise o seguinte recibo ou texto e extraia as informações estruturadas de acordo com o esquema JSON fornecido."
        parts.append(["text": promptText])
        
        if let text = text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(["text": "Texto do usuário: \(text)"])
        }
        
        if let imageData = imageData {
            let base64String = imageData.base64EncodedString()
            let mime = mimeType ?? "image/jpeg"
            parts.append([
                "inlineData": [
                    "mimeType": mime,
                    "data": base64String
                ]
            ])
        }
        
        let schema: [String: Any] = [
            "type": "OBJECT",
            "properties": [
                "storeName": [
                    "type": "STRING",
                    "description": "Nome do estabelecimento, loja ou prestador de serviço."
                ],
                "totalAmount": [
                    "type": "NUMBER",
                    "description": "O valor total gasto em formato numérico decimal."
                ],
                "category": [
                    "type": "STRING",
                    "enum": ["Alimentação", "Transporte", "Lazer", "Saúde", "Outros"],
                    "description": "Categoria do gasto."
                ],
                "date": [
                    "type": "STRING",
                    "description": "Data do gasto no formato YYYY-MM-DD. Se não for especificada, use a data atual (\(currentDateString()))."
                ]
            ],
            "required": ["storeName", "totalAmount", "category", "date"]
        ]
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": parts
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": schema
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.emptyResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorObj = errorJson["error"] as? [String: Any],
               let errorMessage = errorObj["message"] as? String {
                throw GeminiError.apiError(errorMessage)
            }
            throw GeminiError.apiError("Erro HTTP \(httpResponse.statusCode)")
        }
        
        let geminiResponse: GeminiResponse
        do {
            geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        } catch {
            throw GeminiError.parsingError(error)
        }
        
        guard let jsonString = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw GeminiError.emptyResponse
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw GeminiError.emptyResponse
        }
        
        do {
            let analysis = try JSONDecoder().decode(ReceiptAnalysis.self, from: jsonData)
            return analysis
        } catch {
            throw GeminiError.parsingError(error)
        }
    }
    
    func sendChatMessage(history: [ChatMessage], currentExpenses: [ExpenseDTO], newPrompt: String) async throws -> String {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, key != "SUA_API_KEY_AQUI" else {
            throw GeminiError.missingApiKey
        }
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(key)") else {
            throw GeminiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Formatar despesas para contextualizar o modelo
        let expensesJsonString: String
        if let data = try? JSONEncoder().encode(currentExpenses),
           let json = String(data: data, encoding: .utf8) {
            expensesJsonString = json
        } else {
            expensesJsonString = "[]"
        }
        
        let systemPrompt = """
        Você é o Coach Financeiro Inteligente do ExpenseAssistant.
        O usuário tem as seguintes despesas cadastradas no banco de dados local:
        \(expensesJsonString)
        
        Seu objetivo é responder perguntas de forma simpática, prestativa e profissional em Português.
        Faça análises financeiras com base nas despesas acima, dê conselhos sobre economia e ajude-o a manter o orçamento.
        Seja conciso nas respostas e mantenha um tom encorajador.
        Se não houver despesas, informe o usuário amigavelmente e dê dicas gerais de finanças pessoais.
        """
        
        var contents: [[String: Any]] = []
        for message in history {
            let role = message.sender == .user ? "user" : "model"
            contents.append([
                "role": role,
                "parts": [
                    ["text": message.content]
                ]
            ])
        }
        
        contents.append([
            "role": "user",
            "parts": [
                ["text": newPrompt]
            ]
        ])
        
        let systemInstruction: [String: Any] = [
            "parts": [
                ["text": systemPrompt]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "systemInstruction": systemInstruction,
            "contents": contents
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.emptyResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorObj = errorJson["error"] as? [String: Any],
               let errorMessage = errorObj["message"] as? String {
                throw GeminiError.apiError(errorMessage)
            }
            throw GeminiError.apiError("Erro HTTP \(httpResponse.statusCode)")
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let responseText = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw GeminiError.emptyResponse
        }
        
        return responseText
    }
    
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
