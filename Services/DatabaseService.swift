//
//  DatabaseService.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/19/26.
//

import Foundation
import GRDB
import Combine

class DatabaseService {
    static let shared = DatabaseService()
    
    // 数据库连接队列 (线程安全)
    private let dbQueue: DatabaseQueue
    
    init() {
        do {
            // 1. 确定固定的标准路径 (不再支持自定义)
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let directoryURL = appSupportURL.appendingPathComponent("DeskPet_QuanQuan", isDirectory: true)
            
            // 确保目录存在
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            
            let databaseURL = directoryURL.appendingPathComponent("history.sqlite")
            
            // 2. 连接数据库
            // var config = Configuration()
            // config.prepareDatabase { db in db.trace { print($0) } } // 调试用：打印SQL
            dbQueue = try DatabaseQueue(path: databaseURL.path)
            
            // 3. 执行建表
            try migrator.migrate(dbQueue)
            
        } catch {
            fatalError("🔥 数据库初始化极其失败: \(error)")
        }
    }
    
    // MARK: - 建表逻辑
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        // V1 版本：基础表结构
        migrator.registerMigration("createChatMessageTable") { db in
            try db.create(table: "chatMessage") { t in
                t.column("id", .text).primaryKey() // UUID String 主键
                t.column("role", .text).notNull()
                t.column("content", .text).notNull()
                t.column("timestamp", .date).notNull()
                t.column("isPermanent", .boolean).notNull().defaults(to: false)
            }
        }
        return migrator
    }
    
    // MARK: - 增删改 (CRUD)
    
    /// 插入一条数据库记录
    func insert(_ message: ChatMessage) async throws {
        try await dbQueue.write { db in
            try message.insert(db)
        }
    }
    
    /// 保存消息记录
    func addMessage(role: MessageRole, content: String, isPermannent: Bool = false) async throws {
        let message = ChatMessage(
            id: UUID(),         // 自动生成新 ID
            role: role,
            content: content,
            timestamp: Date(),  // 使用当前时间
            isPermanent: isPermannent
        )
        
        try await insert(message)
    }
    
    /// 更新消息内容 (编辑功能)
    func updateContent(id: UUID, newContent: String, newTimestamp: Date) async throws {
        try await dbQueue.write { db in
            if var message = try ChatMessage.fetchOne(db, key: id) {
                message.content = newContent
                message.timestamp = newTimestamp
                try message.update(db)
            }
        }
    }
    
    /// 删除指定 ID 集合
    func delete(ids: Set<UUID>) async throws {
        try await dbQueue.write { db in
            try ChatMessage.deleteAll(db, keys: ids)
        }
    }
    
    /// 清空某一类消息
    func clearAll(isPermanent: Bool) async throws {
        try await dbQueue.write { db in
            try ChatMessage
                .filter(Column("isPermanent") == isPermanent)
                .deleteAll(db)
        }
    }
    
    // MARK: - 数据观察 (UI 自动刷新的核心)
    
    /// 返回两个数组：(临时记录, 永久记忆)
    func observeAllMessages() -> AnyPublisher<(temp: [ChatMessage], perm: [ChatMessage]), Error> {
        let request = ChatMessage.order(Column("timestamp").desc) // 倒序：最新的在上面
        
        return ValueObservation
            .tracking { db in
                let all = try request.fetchAll(db)
                let temp = all.filter { !$0.isPermanent }
                let perm = all.filter { $0.isPermanent }
                return (temp, perm)
            }
            .publisher(in: dbQueue)
            .eraseToAnyPublisher()
    }
    
    // MARK: - AI 专用查询
    
    /// 获取 AI 上下文 (永久记忆 + 最近 N 条临时记忆)
    func getContextForAI(limit: Int) async throws -> [ChatMessage] {
        try await dbQueue.read { db in
            // 1. 所有永久记忆 (正序)
            let perms = try ChatMessage
                .filter(Column("isPermanent") == true)
                .order(Column("timestamp").asc)
                .fetchAll(db)
            
            // 2. 最近 N 条临时记忆 (先倒序取 limit，再正序排)
            let temps = try ChatMessage
                .filter(Column("isPermanent") == false)
                .order(Column("timestamp").desc)
                .limit(limit+1)
                .fetchAll(db)
                .sorted { $0.timestamp < $1.timestamp }
            
            /*
            // 3. 格式化 (加时间戳)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let timestampedTemps = temps.map { msg -> ChatMessage in
                var newMsg = msg
                let timeStr = formatter.string(from: msg.timestamp)
                newMsg.content = "[\(timeStr)] \(msg.content)"
                return newMsg
            }
            */
            
            return perms + temps
        }
    }
    
    // MARK: - 导入导出 (JSON 格式)
    
    func exportToJSON() async throws -> Data {
        try await dbQueue.read { db in
            let all = try ChatMessage.fetchAll(db)
            let storage = HistoryStorage(
                temporary: all.filter { !$0.isPermanent },
                permanent: all.filter { $0.isPermanent }
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(storage)
        }
    }
    
    /// 导入 JSON 并去重
    func importFromJSON(url: URL) async throws {
        // 1. 安全读取
        let gotAccess = url.startAccessingSecurityScopedResource()
        defer { if gotAccess { url.stopAccessingSecurityScopedResource() } }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // JSON 临时解码结构
        struct ImportStorage: Codable {
            struct ImportMessage: Codable {
                let id: UUID
                let role: MessageRole
                let content: String
                let timestamp: Date
                // 把 isPermanent 设为可选 (Bool?)
                // 这样旧数据(没有这个字段)和新数据(有这个字段)都能解析成功
                let isPermanent: Bool?
            }
            let temporary: [ImportMessage]
            let permanent: [ImportMessage]
        }
        
        // 2. 将数据解码成临时结构体
        let storage = try decoder.decode(ImportStorage.self, from: data)
        
        // 2. 写入数据库 (事务处理)
        try await dbQueue.write { db in
            // 处理临时记录 (强制 isPermanent = false)
            for rawMsg in storage.temporary {
                // 将临时结构转为正式结构 [ChatMessage]
                let finalMsg = ChatMessage(
                    id: rawMsg.id,
                    role: rawMsg.role,
                    content: rawMsg.content,
                    timestamp: rawMsg.timestamp,
                    // 逻辑：因为它是从 temporary 数组里出来的，所以它肯定是 false
                    // 即使 JSON 里没有这个字段也不怕
                    isPermanent: false
                )
                try finalMsg.insert(db, onConflict: .ignore)
            }
            
            // 处理永久记录 (强制 isPermanent = true)
            for rawMsg in storage.permanent {
                let finalMsg = ChatMessage(
                    id: rawMsg.id,
                    role: rawMsg.role,
                    content: rawMsg.content,
                    timestamp: rawMsg.timestamp,
                    // 逻辑：因为它是从 permanent 数组里出来的，所以它肯定是 true
                    isPermanent: true
                )
                try finalMsg.insert(db, onConflict: .ignore)
            }
        }
        print("✅ 导入完成: \(url.lastPathComponent)")
    }
}
