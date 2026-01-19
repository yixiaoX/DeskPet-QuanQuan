//
//  HistoryManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/14/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    // --- 设置项 (改为标准 UserDefaults 写法，确保持久化且能刷新 UI) ---
    @Published var contextLimit: Int {
        didSet { UserDefaults.standard.set(contextLimit, forKey: "historyContextLimit") }
    }
    
    @Published var customPathString: String {
        didSet { UserDefaults.standard.set(customPathString, forKey: "customHistoryPath") }
    }
    
    // --- 运行时数据 ---
    @Published var storage: HistoryStorage = HistoryStorage()
    
    // 总结字数限制 (默认 50)
    @Published var summaryWordLimit: Int {
        didSet { UserDefaults.standard.set(summaryWordLimit, forKey: "historySummaryLimit") }
    }
    
    // 默认路径
    private var defaultPath: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let docDir = paths[0].appendingPathComponent("DeskPet_QuanQuan")
        try? FileManager.default.createDirectory(at: docDir, withIntermediateDirectories: true)
        return docDir.appendingPathComponent("History.json")
    }
    
    // 实际使用的路径
    var activeFileURL: URL {
        if !customPathString.isEmpty, let url = URL(string: customPathString) {
            return url
        }
        return defaultPath
    }
    
    init() {
        // 从 UserDefaults 读取初始值
        self.contextLimit = UserDefaults.standard.object(forKey: "historyContextLimit") as? Int ?? 10
        self.customPathString = UserDefaults.standard.string(forKey: "customHistoryPath") ?? ""
        self.summaryWordLimit = UserDefaults.standard.object(forKey: "historySummaryLimit") as? Int ?? 50
        
        loadHistory()
    }
    
    // MARK: - 📁 文件操作
    
    func loadHistory() {
        // 如果文件不存在，什么都不做，使用默认空记录
        guard FileManager.default.fileExists(atPath: activeFileURL.path) else {
            print("📜 没有找到历史记录文件，将创建新的。路径: \(activeFileURL.path)")
            return
        }
        
        do {
            let data = try Data(contentsOf: activeFileURL)
            let decoder = JSONDecoder()
            
            // 格式化日期，使其在 json 中可读（可选）
            // ⚠️如果修改需要同步修改saveHistory函数中的对应项
            decoder.dateDecodingStrategy = .iso8601
            
            storage = try decoder.decode(HistoryStorage.self, from: data)
            print("✅ 成功加载历史记录: \(storage.permanent.count)条永久, \(storage.temporary.count)条临时")
        } catch {
            print("❌ 历史记录加载失败 (可能是格式旧了): \(error)")
            // 这里不覆盖 storage，防止读取错误时把内存里的数据清空
        }
    }
    
    func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            // 格式化日期，使其在 json 中可读（可选）
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(storage)
            try data.write(to: activeFileURL)
            print("💾 历史记录已保存")
        } catch {
            print("❌ 保存历史记录失败: \(error)")
        }
    }
    
    // MARK: - 🧠 给 AI 准备数据
    
    func getContextForAI() -> [ChatMessage] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 读取永久记忆
        let perm = storage.permanent
        
        // 按照时间顺序读取最新的 contextLimit 条对话记录
        let sortedTemp = storage.temporary.sorted { $0.timestamp < $1.timestamp }
        let recentTemp = Array(sortedTemp.suffix(contextLimit))
        
        // 为最新对话记录加入时间戳
        let timestampedTemp = recentTemp.map { msg -> ChatMessage in
            let timeString = formatter.string(from: msg.timestamp)
            
            // 格式化为: "[2026-02-05 10:30:00] 消息内容"
            let newContent = "[\(timeString)] \(msg.content)"
            
            // 返回一个新的对象，不会修改 storage 里存储的原始数据
            return ChatMessage(
                id: msg.id,
                role: msg.role,
                content: newContent,
                timestamp: msg.timestamp
            )
        }
        
        return perm + timestampedTemp
    }
    
    // MARK: - ➕ 增删改查
    
    func addMessage(role: MessageRole, content: String) {
        // 确保 UI 更新在主线程
        DispatchQueue.main.async {
            let msg = ChatMessage(role: role, content: content, timestamp: Date())
            self.storage.temporary.append(msg)
            self.saveHistory()
        }
    }
    
    func move(items: Set<UUID>, fromSource: inout [ChatMessage], toDest: inout [ChatMessage]) {
        // 找到要移动的项目
        let itemsToMove = fromSource.filter { items.contains($0.id) }
        
        guard !itemsToMove.isEmpty else { return }
        
        // 执行移动
        fromSource.removeAll { items.contains($0.id) }
        toDest.append(contentsOf: itemsToMove)
        // 重新按时间排序
        toDest.sort { $0.timestamp < $1.timestamp }
        
        saveHistory()
    }
    
    // MARK: - 📁 导入导出与数据管理 (新增)
    
    /// 从外部文件导入历史记录 (会覆盖当前内存中的数据)
    func importHistory(from url: URL) throws {
        // 1. 获取安全访问权限 (沙盒机制)
        let gotAccess = url.startAccessingSecurityScopedResource()
        defer { if gotAccess { url.stopAccessingSecurityScopedResource() } }
        
        // 2. 读取数据
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // 3. 解码
        let newStorage = try decoder.decode(HistoryStorage.self, from: data)
        
        // 4. 更新内存并保存到默认路径
        DispatchQueue.main.async {
            self.storage = newStorage
            self.saveHistory()
            print("✅ 成功导入外部备份: \(url.path)")
        }
    }
    
    /// 清空所有临时对话历史
    func clearAllTemporary() {
        DispatchQueue.main.async {
            self.storage.temporary.removeAll()
            self.saveHistory()
        }
    }
    
    /// 清空所有永久记忆
    func clearAllPermanent() {
        DispatchQueue.main.async {
            self.storage.permanent.removeAll()
            self.saveHistory()
        }
    }
}
