//
//  HistorySettingsViewModel.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/14/26.
//

import SwiftUI
import Combine

@MainActor
class HistorySettingsViewModel: ObservableObject {
    // 依赖注入
    private let dbService = DatabaseService.shared
    private let chatService = ChatService.shared
    
    // 调取归档字数设置项
    private var summaryLimit: Int { UserDefaults.standard.object(forKey: "history_summary_limit") as? Int ?? 50 }
    
    // --- 数据源 (View 直接读这里) ---
    @Published var temporaryMessages: [ChatMessage] = []
    @Published var permanentMessages: [ChatMessage] = []
    
    // --- UI 状态 ---
    @Published var selectedTempIDs = Set<UUID>()
    @Published var selectedPermIDs = Set<UUID>()
    
    @Published var editingMessage: ChatMessage?
    var isEditingPermanent: Bool = false
    
    @Published var isSummarizing = false
    @Published var showFileImporter = false
    @Published var showFileExporter = false
    @Published var showClearTempAlert = false
    @Published var showClearPermAlert = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    
    @Published var exportDocument: JSONFileDocument?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupDataObservation()
    }
    
    // MARK: - 1. 数据绑定 (核心)
    private func setupDataObservation() {
        // 只要数据库一变，这两个数组自动更新
        dbService.observeAllMessages()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let err) = completion {
                    print("DB 监控出错: \(err)")
                }
            } receiveValue: { [weak self] (temp, perm) in
                self?.temporaryMessages = temp
                self?.permanentMessages = perm
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 2. 导入导出
    func prepareExport() {
        Task {
            do {
                let data = try await dbService.exportToJSON()
                self.exportDocument = JSONFileDocument(jsonData: data)
                self.showFileExporter = true
            } catch {
                showError("导出准备失败: \(error.localizedDescription)")
            }
        }
    }
    
    func handleImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            Task {
                do {
                    try await dbService.importFromJSON(url: url)
                    // 不需要刷新代码，DatabaseService 写入后会自动触发 setupDataObservation
                } catch {
                    showError("导入失败: \(error.localizedDescription)")
                }
            }
        case .failure(let error):
            showError("选文件出错: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 3. 总结归档
    func summarizeAndMoveToPermanent() async {
        let itemsToMove = temporaryMessages
            .filter { selectedTempIDs.contains($0.id) }
            .sorted { $0.timestamp < $1.timestamp }
        
        guard !itemsToMove.isEmpty else { return }
        isSummarizing = true
        
        do {
            let summaryText = try await chatService.summarizeMemories(messages: itemsToMove, limit: summaryLimit)
            
            try await dbService.addMessage(role: .ai, content: summaryText, isPermannent: true)
            
            // (可选) 可以在这里删除已总结的临时条目
            // try await dbService.delete(ids: selectedTempIDs)
            
            selectedTempIDs.removeAll()
        } catch {
            showError("总结失败: \(error.localizedDescription)")
        }
        isSummarizing = false
    }
    
    // MARK: - 4. 增删改
    func deleteSelectedTemp() {
        // 选中的 ID 保存副本
        let idsToDelete = selectedTempIDs
        // 清空选中态
        selectedTempIDs.removeAll()
        // 执行删除
        Task {
            try? await dbService.delete(ids: idsToDelete)
        }
    }
    
    func deleteSelectedPerm() {
        let idsToDelete = selectedPermIDs
        selectedPermIDs.removeAll()
        Task {
            try? await dbService.delete(ids: idsToDelete)
        }
    }
    
    func clearAllTemporary() {
        Task { try? await dbService.clearAll(isPermanent: false) }
    }
    
    func clearAllPermanent() {
        Task { try? await dbService.clearAll(isPermanent: true) }
    }
    
    func startEditing(_ msg: ChatMessage, isPermanent: Bool) {
        self.isEditingPermanent = isPermanent
        self.editingMessage = msg
    }
    
    func saveEdits(newContent: String, newDate: Date) {
        guard let id = editingMessage?.id else { return }
        Task {
            try? await dbService.updateContent(id: id, newContent: newContent, newTimestamp: newDate)
        }
        editingMessage = nil
    }
    
    private func showError(_ msg: String) {
        self.errorMessage = msg
        self.showErrorAlert = true
    }
}
