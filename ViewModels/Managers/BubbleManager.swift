//
//  BubbleManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/16/26.
//

import SwiftUI
import Combine

@MainActor
class BubbleManager: ObservableObject {
    
    // MARK: - ⚙️ 用户偏好设置
    
    // 模式1: 气泡出现时，总是顺便把输入框也显示出来
    @AppStorage("alwaysShowInputInBubble") var alwaysShowInputInBubble: Bool = false {
        didSet { objectWillChange.send() }
    }
    
    // 模式2: 输入框常驻 (霸道模式)
    @AppStorage("isInputPermanent") var isInputPermanent: Bool = false {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - 💬 状态数据
    
    @Published var text: String = ""          // 当前显示的文字 (打字机效果中)
    @Published var userInput: String = ""     // 用户输入的内容
    
    @Published var isBubbleVisible: Bool = false // 气泡本体开关
    @Published var isInputActive: Bool = false   // 输入框本体开关
    @Published var isTyping: Bool = false        // 是否正在以打字机模式显示文字
    
    private var fullTextCache: String = ""       // 缓存完整文字
    private var typingTask: Task<Void, Never>?   // 打字任务
    
    // MARK: - 🧠 计算属性 (UI 直接绑定这些)
    
    /// 最终决定是否显示输入框
    var shouldShowInput: Bool {
        if isInputPermanent { return true }
        if alwaysShowInputInBubble { return true }
        return isInputActive
    }
    
    /// 最终决定是否显示气泡容器
    var shouldShowContainer: Bool {
        if isInputPermanent { return true }
        return isBubbleVisible
    }
    
    // MARK: - 🕹️ 控制方法
    
    /// 开始打字机效果
    func startTyping(text: String) {
        // 1. 重置
        typingTask?.cancel()
        fullTextCache = text
        self.text = ""
        self.isTyping = true
        self.isBubbleVisible = true // 确保气泡可见
        
        // 2. 开始逐字显示
        typingTask = Task {
            for char in text {
                if Task.isCancelled { return }
                
                await MainActor.run {
                    if !Task.isCancelled {
                        self.text.append(char)
                    }
                }
                // 调节打字速度
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
            
            await MainActor.run {
                if !Task.isCancelled {
                    self.isTyping = false
                }
            }
        }
    }
    
    /// 跳过打字，直接显示全部
    func skipTyping() {
        guard isTyping else { return }
        typingTask?.cancel()
        text = fullTextCache
        isTyping = false
    }
    
    /// 显示纯输入框（点击唤起时）
    func showInputPanel() {
        // 如果不是常驻模式，才需要手动打开
        if !isInputPermanent {
            isBubbleVisible = true
            isInputActive = true
        }
    }
    
    /// 关闭气泡后清空文字
    func closeBubble() {
        // 1. 如果是常驻模式，只清空文字不关闭
        if isInputPermanent {
            self.text = ""
            return
        }
        
        // 2. 先改变状态，触发 View 的淡出动画
        // (View 层应该已经绑定了 .animation，所以这里直接改值即可)
        isBubbleVisible = false
        isInputActive = false
        
        // 3. 延迟清空内容 (核心优化)
        // 0.5秒通常足够 spring 动画执行完毕
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // 双重检查：确保用户没有在这 0.5 秒内又重新打开了气泡
            // 如果用户手快又点开了，我们就不清空了，防止刚打出来的字消失
            if !self.isBubbleVisible {
                self.text = ""
                // self.userInput = "" // 如果你想连输入框草稿也清空，取消注释这行
            }
        }
    }
    
    /// 清空并准备输入
    func clearInput() {
        userInput = ""
    }
}
