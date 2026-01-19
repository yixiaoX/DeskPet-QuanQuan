//
//  HistoryModel.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/14/26.
//

import Foundation
import GRDB // SQLite 管理包

enum MessageRole: String, Codable {
    case user
    case ai
    case system // 预留给系统提示词
}

struct ChatMessage: Identifiable, Codable, Equatable, FetchableRecord, PersistableRecord {
    var id: UUID = UUID()
    let role: MessageRole
    var content: String
    var timestamp: Date
    
    // 区分临时记录 (false) 和永久记忆 (true)
    var isPermanent: Bool = false
    
    // GRDB 列映射
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let role = Column(CodingKeys.role)
        static let content = Column(CodingKeys.content)
        static let timestamp = Column(CodingKeys.timestamp)
        static let isPermanent = Column(CodingKeys.isPermanent)
    }
}

// 导入导出 JSON 文件的容器
struct HistoryStorage: Codable {
    var temporary: [ChatMessage] = [] // 左侧：临时记录
    var permanent: [ChatMessage] = [] // 右侧：永久记录
}
