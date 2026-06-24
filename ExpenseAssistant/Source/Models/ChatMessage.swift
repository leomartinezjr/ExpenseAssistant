import Foundation

struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let sender: MessageSender
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), sender: MessageSender, content: String, timestamp: Date = Date()) {
        self.id = id
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
    }
}

enum MessageSender: String, Codable, Equatable, Sendable {
    case user
    case assistant
}
