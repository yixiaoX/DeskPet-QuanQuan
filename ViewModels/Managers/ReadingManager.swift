//
//  ReadingManager.swift
//  DeskPet-QuanQuan
//  这个模块负责定时调用 ClipboardService 扫描剪切板，然后调用 ChatService 发送给 AI 进行评价
//
//  Created by Yixiao Chen on 1/14/26.
//

import Foundation

class ReadingManager {
    // 依赖
    private let clipboardService = ClipboardService.shared
    private let chatService = ChatService.shared
    private let historyManager = HistoryManager.shared
    
    
    // 状态
    var isReading = false
    private var readingTimer: Timer?
    
    // 回调：(原文片段, AI吐槽) -> Void
    var onReviewGenerated: ((String) -> Void)?
    
    // 状态标记：防止一次请求还没回来，下一次请求又发出去
    private var isProcessing = false
    
    // 切换开关
    func toggleReading() -> Bool {
        isReading.toggle()
        if isReading {
            startReading()
        } else {
            stopReading()
        }
        return isReading
    }
    
    private func startReading() {
        // print("📖 开启一起看书模式")
        isReading = true
        
        // 1. 同步剪贴板状态，忽略开启之前的复制内容
        clipboardService.syncChangeCount()
        
        // 2. 启动定时器 (每 2 秒检查一次)
        readingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func stopReading() {
        // print("📕 关闭一起看书模式")
        isReading = false
        readingTimer?.invalidate()
        readingTimer = nil
    }
    
    private func checkClipboard() {
        // 如果正在等待 AI 回复，先暂停扫描，避免请求堆积
        guard !isProcessing else { return }
        
        // 获取新内容
        let (isNew, content) = clipboardService.fetchNewTextContent()
        
        if isNew, let text = content {
            // print("检测到新剪贴板内容，长度: \(text.count)")
            // historyManager.addMessage(role: .user, content: "📖" + text)    // 存入历史记录
            handleNewContent(text)
        }
    }
    
    private func handleNewContent(_ text: String) {
        isProcessing = true
        
        Task {
            do {
                // 调用 ChatService 的 reviewReading
                let review = try await chatService.reviewReading(content: text)
                historyManager.addMessage(role: .ai, content: "📖 [书评] \(review)")    // 存入历史记录
                await MainActor.run {
                    // 触发回调通知 ViewModel
                    self.onReviewGenerated?(review)
                    self.isProcessing = false
                }
            } catch {
                print("阅读评价失败: \(error)")
                self.isProcessing = false
            }
        }
    }
}
