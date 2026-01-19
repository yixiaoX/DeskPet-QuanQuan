//
//  ChatManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/14/26.
//

import Foundation

class ChatManager {
    static let shared = ChatManager()
    
    private let chatService = ChatService.shared
    private let dbService = DatabaseService.shared

    private var contextLimit: Int { UserDefaults.standard.object(forKey: "log_context_limit") as? Int ?? 50 }
    
    func sendMessage(_ text: String) async throws -> String {
        // 1. 把用户的消息存入历史
        try await dbService.addMessage(role: .user, content: text)
        
        // 2. 获取构建好的上下文 (永久 + 最近N条临时)
        // 这里的 contextMessages 是 [ChatMessage] 数组
        let contextMessages = try await dbService.getContextForAI(limit: contextLimit)
        
        // 3. 发送给 Service
        let reply = try await chatService.generateChatReply(history: contextMessages)
        
        // 4. 把 AI 的回复存入历史
        try await dbService.addMessage(role: .ai, content: reply)
        
        return reply
    }
}
