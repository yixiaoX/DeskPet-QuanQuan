//
//  HistorySettingsViewModel.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/14/26.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

// 定义导出文档格式 (用于 SwiftUI fileExporter)
struct HistoryJSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var storage: HistoryStorage
    
    init(storage: HistoryStorage) {
        self.storage = storage
    }
    
    init(configuration: ReadConfiguration) throws {
        // 导出不需要实现读取，但协议要求
        let data = configuration.file.regularFileContents ?? Data()
        self.storage = try JSONDecoder().decode(HistoryStorage.self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(storage)
        return FileWrapper(regularFileWithContents: data)
    }
}

@MainActor
class HistorySettingsViewModel: ObservableObject {
    // 引用单例
    @ObservedObject var manager = HistoryManager.shared
    
    // 总结永久记忆需要用到 ChatService
    private let chatService = ChatService.shared
    
    // 选中的 ID (这些是 UI 状态，只跟记忆管理界面有关)
    @Published var selectedTempIDs = Set<UUID>()
    @Published var selectedPermIDs = Set<UUID>()
    
    // 编辑状态管理
    @Published var editingMessage: ChatMessage? // 当前正在编辑的消息对象
    var isEditingPermanent: Bool = false // 标记正在编辑的是哪一边的 (true=右边, false=左边)
    
    // 永久记忆加载状态
    @Published var isSummarizing = false
    
    @Published var showFileImporter = false
    @Published var showFileExporter = false
    
    @Published var showClearTempAlert = false
    @Published var showClearPermAlert = false
    
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    
    // 导出时生成文档
    func getExportDocument() -> HistoryJSONDocument {
        return HistoryJSONDocument(storage: manager.storage)
    }
    
    // 处理导入结果
    func handleImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                try manager.importHistory(from: url)
            } catch {
                self.errorMessage = "导入失败：\(error.localizedDescription)"
                self.showErrorAlert = true
            }
        case .failure(let error):
            self.errorMessage = "文件选择错误：\(error.localizedDescription)"
            self.showErrorAlert = true
        }
    }
    
    // 处理导出结果
    func handleExport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("导出成功: \(url)")
        case .failure(let error):
            self.errorMessage = "导出失败：\(error.localizedDescription)"
            self.showErrorAlert = true
        }
    }
    
    // 向右移动 (临时 -> 永久)
    func summarizeAndMoveToPermanent() async {
        // 1. 获取选中的消息对象 (保持时间顺序)
        let itemsToMove = manager.storage.temporary
            .filter { selectedTempIDs.contains($0.id) }
            .sorted { $0.timestamp < $1.timestamp }
        
        guard !itemsToMove.isEmpty else { return }
        
        // 2. 开启加载状态
        await MainActor.run { self.isSummarizing = true }
        
        do {
            // 3. 调用 AI 进行总结
            // 获取用户设置的字数限制
            let limit = manager.summaryWordLimit
            let summaryText = try await chatService.summarizeMemories(messages: itemsToMove, limit: limit)
            
            await MainActor.run {
                // 4. 创建新的永久记忆条目
                // 这里我们用 .system 或者 .ai 都可以，建议用 .system 代表这是“内心独白/记忆”
                // 或者为了方便聊天时回显，依然用 .ai，但内容是总结过的
                let memoryMsg = ChatMessage(
                    role: .ai, // 或者 .system
                    content: "📝 [记忆] \(summaryText)", // 加个标记方便识别
                    timestamp: Date()
                )
                
                // 5. 写入永久记录
                self.manager.storage.permanent.append(memoryMsg)
                
                // 6. 保存并关闭加载
                self.manager.saveHistory()
                self.isSummarizing = false
            }
        } catch {
            await MainActor.run {
                print("总结失败: \(error)")
                self.isSummarizing = false
                // 可选：这里可以弹个 Alert 告诉用户总结失败了
            }
        }
    }
    
    // 删除选中的记录
    func deleteSelectedTemp() {
        // 从数组中移除 ID 在选中集合里的项
        manager.storage.temporary.removeAll { selectedTempIDs.contains($0.id) }
        selectedTempIDs.removeAll() // 清空选中态
        manager.saveHistory()       // 保存到磁盘
    }
    
    func deleteSelectedPerm() {
        manager.storage.permanent.removeAll { selectedPermIDs.contains($0.id) }
        selectedPermIDs.removeAll()
        manager.saveHistory()
    }

    // 准备开始编辑
    func startEditing(_ msg: ChatMessage, isPermanent: Bool) {
        DispatchQueue.main.async {
            self.isEditingPermanent = isPermanent
            self.editingMessage = msg
        }
    }
    
    // 保存修改
    func saveEdits(newContent: String, newDate: Date) {
        guard let editingID = editingMessage?.id else { return }
        
        if isEditingPermanent {
            // 在永久记录里找
            if let index = manager.storage.permanent.firstIndex(where: { $0.id == editingID }) {
                // 修改内容 (创建新结构体，因为 struct 是值类型)
                let oldMsg = manager.storage.permanent[index]
                
                let updatedMsg = ChatMessage(
                    id: oldMsg.id,
                    role: oldMsg.role,
                    content: newContent,
                    timestamp: newDate
                )
                manager.storage.permanent[index] = updatedMsg
            }
        } else {
            // 在临时记录里找
            if let index = manager.storage.temporary.firstIndex(where: { $0.id == editingID }) {
                let oldMsg = manager.storage.temporary[index]
                let updatedMsg = ChatMessage(
                    id: oldMsg.id,
                    role: oldMsg.role,
                    content: newContent,
                    timestamp: newDate
                )
                manager.storage.temporary[index] = updatedMsg
            }
        }
        
        manager.saveHistory()
        editingMessage = nil // 关闭弹窗
    }
}
