//
//  HistoryModel.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/14/26.
//

import Foundation

enum MessageRole: String, Codable {
    case user
    case ai
    case system // 预留给系统提示词
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
}

struct HistoryStorage: Codable {
    var temporary: [ChatMessage] = [] // 左侧：临时记录
    var permanent: [ChatMessage] = [] // 右侧：永久记录
}
