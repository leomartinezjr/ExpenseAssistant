import Foundation
import Security

struct KeychainHelper {
    static let serviceName = "com.leomartinez.ExpenseAssistant"
    
    // Suporte para testes unitários ou ambientes sem Keychain físico
    nonisolated(unsafe) static var useInMemoryMock = false
    nonisolated(unsafe) private static var mockStorage: [String: String] = [:]
    
    @discardableResult
    static func save(key: String, value: String) -> Bool {
        if useInMemoryMock {
            mockStorage[key] = value
            return true
        }
        
        guard let data = value.data(using: .utf8) else { return false }
        
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ] as [String: Any]
        
        // Remove item existente se houver
        SecItemDelete(query as CFDictionary)
        
        // Adiciona novo item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func read(key: String) -> String? {
        if useInMemoryMock {
            return mockStorage[key]
        }
        
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    @discardableResult
    static func delete(key: String) -> Bool {
        if useInMemoryMock {
            mockStorage.removeValue(forKey: key)
            return true
        }
        
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ] as [String: Any]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
