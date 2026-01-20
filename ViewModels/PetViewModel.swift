//
//  PetViewModel.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import SwiftUI
import Combine

// 动作枚举
enum PetAction {
    case idle, eating, sleeping, happy, dragging, sad, speaking, keepSleeping
    
    var gifName: String {
        switch self {                               // 时长（秒）
        case .idle:         return "stand.gif"      // 5.1
        case .eating:       return "eat.gif"        // 5.1
        case .sleeping:     return "sleep.gif"      // 5.1
        case .happy:        return "happy.gif"      // 5.1
        case .dragging:     return "up.gif"         // 5.1
        case .sad:          return "sad.gif"        // 4.1
        case .speaking:     return "speak.gif"      // 5.1
        case .keepSleeping: return "keep_sleep.gif" // 3.4
            
        }
    }
}

@MainActor
class PetViewModel: ObservableObject {
    // --- 读取配置 ---
    private var defaults: UserDefaults { UserDefaults.standard }
    private var petName: String { defaults.string(forKey: "pet_name") ?? "泉泉" }
    private var petCall: String { defaults.string(forKey: "pet_call_user") ?? "主人" }
    
    // --- UI 状态 ---
    @Published var currentAction: PetAction = .idle
    @Published var showBubble: Bool = false
    @Published var bubbleText: String = "..."
    @Published var showInput: Bool = false
    @Published var userInput: String = ""
    @Published var isAutoListening: Bool = false
    @Published var isReading: Bool = false
    
    // UI 置顶选项开关
    @AppStorage("isAlwaysOnTop") var isAlwaysOnTop: Bool = true {
        didSet {
            updateWindowLevel()
        }
    }
    
    // MARK: 内部状态
    private var resetTask: DispatchWorkItem? // 核心：用来管理倒计时复原
    
    // --- 模块管理器 ---
    @Published var bubbleManager = BubbleManager()     // 定义气泡管理器变量让 View 可以直接访问
    
    private let stats = StatsManager.shared //商店数据源
    private let storeManager: StoreWindowManager
    private let gameManager: GameWindowManager
    
    private let chatService = ChatService.shared // 基础服务
    private let chatManager = ChatManager.shared
    private let interactionManager: InteractionManager
    private let musicManager: MusicManager
    private let readingManager: ReadingManager
    
    // 监控模块状态变化
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 1. 初始化管理器
        self.interactionManager = InteractionManager()
        self.musicManager = MusicManager()
        self.readingManager = ReadingManager()
        self.storeManager = StoreWindowManager()
        self.gameManager = GameWindowManager()
        
        // 2. 绑定各功能回调 (神经连接)
        setupBindings()
    }
    
    private func setupBindings() {
        // 听歌状态更新
        musicManager.onStatusChange = { [weak self] status in
            // duration: 0 表示一直显示，直到下一次更新
            self?.performAction(action: .happy, msg: status, duration: 3.0)
        }
        
        // 听歌评价更新
        musicManager.onReviewGenerated = { [weak self] review in
            self?.performAction(action: .speaking, msg: review, duration: 5.0)
        }
        
        // 书评更新
        readingManager.onReviewGenerated = { [weak self] review in
            self?.performAction(action: .speaking, msg: review, duration: 5.0)
        }
        
        // 互动/睡眠回调
        interactionManager.onRequestAction = { [weak self] action, msg, duration in
            guard let self = self else { return }
            
            // 🚨 关键判断：什么情况下允许执行新动作？
            
            // 情况 A: 当前没事干 (.idle)，允许被打断
            let isIdle = (self.currentAction == .idle)
            
            // 情况 B: 这是一个“强制动作” (比如睡觉、被摸头)，无论你在干嘛都要执行
            // 注意：我们不想打断吃饭 (.eating)，所以加个判断
            let isForceAction = (action == .sleeping || action == .speaking || action == .happy || action == .sad)
            
            // 综合判断：如果是强制动作，且不是在吃饭；或者当前是空闲
            if (isForceAction && self.currentAction != .eating) || isIdle {
                self.performAction(action: action, msg: msg, duration: duration)
            }
        }
        
        // 气泡样式更新
        // 当 bubbleManager 发生变化时 (比如打字、显示/隐藏)，
        // 手动触发 PetViewModel 的更新，这样 ContentView 才会重绘
        bubbleManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // MARK: - 监听专注模式信号
        FocusManager.shared.eventSubject
            .receive(on: RunLoop.main) // 确保在主线程接收，因为要更新 UI
            .sink { [weak self] event in
                guard let self = self else { return }
                
                switch event {
                case .warning(let msg):
                    // 触发“生气”动作，并显示警告气泡
                    self.performAction(action: .sad, msg: msg, duration: 5.0)
                    
                case .reward(let reward):
                    self.interactionManager.startTimers()
                    Task{
                        let res = try await self.interactionManager.focusCompleted(reward)
                        // 触发“开心”动作
                        self.performAction(action: res.action, msg: res.msg, duration: res.duration)
                    }
                    
                case .breakFocus:
                    self.interactionManager.recordInteraction()
                    self.interactionManager.startTimers()
                    
                case .start(let minutes):
                    self.interactionManager.stopTimers()
                    // 显示提示
                    self.performAction(action: .speaking, msg: "好的！我们要开始专注 \(minutes) 分钟了，我会盯着\(petCall)的！", duration: 3.0)
                }
            }
            .store(in: &cancellables) // 绑定生命周期
    }
    
    
    // MARK: - ⚙️ 核心控制台 (State Coordinator)
    /// 统一执行动作、显示气泡、并设置自动复原倒计时
    private func performAction(action: PetAction, msg: String? = nil, duration: TimeInterval) {
        // 打断之前的倒计时 (比如刚喂食还没吃完，又让它睡觉，那“吃完复原”的任务就取消)
        resetTask?.cancel()
        // 执行非睡眠动作时，重置睡眠计时
        if action != .sleeping && action != .keepSleeping {
            interactionManager.recordInteraction()
        }
        
        // 1. 更新 UI
        withAnimation {
            self.currentAction = action
        }
        
        // 2. 指挥 BubbleManager 说话 (如果有内容)
        if let message = msg, !message.isEmpty {
            bubbleManager.startTyping(text: message)
        }
        
        // 3. 设置自动复原 (如果 duration > 0)
        if duration > 0 {
            let task = DispatchWorkItem { [weak self] in
                withAnimation {
                    self?.currentAction = .idle
                    // 复原时是否关气泡？取决于设计。
                    // self?.bubbleManager.closeBubble()
                }
            }
            resetTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
        }
    }
    
    // MARK: -  基础互动 (委托给 InteractionManager)
    func sleep() {
        let res = interactionManager.sleep()
        performAction(action: res.action, msg: res.msg, duration: res.duration)
    }
    
    func interact() { // 目前调用的功能用于测试气泡的长文本显示
        let res = interactionManager.interact()
        performAction(action: res.action, msg: res.msg, duration: res.duration)
    }
    
    func scold() async throws {
        let res = try await interactionManager.scold()
        performAction(action: res.action, msg: res.msg, duration: res.duration)
    }
    
    func openStore() {
        storeManager.openStore(with: self)
    }
    
    func feed(food: String) async throws { // 投喂食物
        let res = try await interactionManager.feed(food)
        performAction(action: res.action, msg: res.msg, duration: res.duration)
    }
    
    // MARK: - 🎮 小游戏功能
    
    func openGameCenter() {
        gameManager.show(with: self)
    }
    
    func gameResult(action: PetAction, msg: String? = nil, duration: TimeInterval) {
        performAction(action: action, msg: msg, duration: duration)
    }
    
    
    // MARK: - 💬 聊天 (委托给 ChatManager)
    
    func enableInput() {
        // 唤起输入框
        bubbleManager.showInputPanel()
        // 配合动作
        performAction(action: .happy, duration: 5.0)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func commitChat() {
        // 从 manager 获取输入
        guard !bubbleManager.userInput.isEmpty else { return }
        let textToSend = bubbleManager.userInput
        bubbleManager.clearInput()
        
        // 1. 立即显示思考
        bubbleManager.startTyping(text: "...")
        performAction(action: .happy, duration: 0) // 切换到开心状态等待
        
        // 2. 网络请求
        Task {
            do {
                let reply = try await chatManager.sendMessage(textToSend)
                // 收到回复，指挥 manager 打字
                bubbleManager.startTyping(text: reply)
                // 切换到说话动作
                performAction(action: .speaking, msg: nil, duration: 5.0)
            } catch {
                bubbleManager.startTyping(text: "脑子短路了...")
                performAction(action: .sad, duration: 4.0)
            }
        }
    }
    
    // MARK: - 🎵 音乐 (委托给 MusicManager)
    
    func toggleMusicListening() {
        let newState = musicManager.toggleListening()
        self.isAutoListening = newState
        
        if newState {
            performAction(action: .speaking, msg: "好哒，我会竖起耳朵专心听的！(监听已开启)", duration: 5.0)
        } else {
            performAction(action: .idle, msg: "那我休息一会儿耳朵~ (监听已关闭)", duration: 5.0)
        }
    }
    
    // MARK: - 📚 看书 (委托给 ReadingManager)
    
    func toggleBookReading() {
        let newState = readingManager.toggleReading()
        self.isReading = newState
        
        if newState {
            performAction(action: .speaking, msg: "开启‘一起看书’模式，你复制的内容我都会看哦~", duration: 5.0)
        } else {
            performAction(action: .idle, msg: "已退出‘一起看书’模式。", duration: 5.0)
        }
    }
    
    // MARK: - ✋ 拖拽行为
    
    func startDragging() {
        interactionManager.recordInteraction() // ⚡️ 记为交互
        // 拎起来的时候，立刻取消所有“变回发呆”的倒计时
        resetTask?.cancel()
        
        if currentAction != .dragging {
            withAnimation {
                currentAction = .dragging
                // 拖拽时不让它显示气泡，或者可以说一句“放我下来”
                // showBubble = false
            }
        }
    }
    
    func endDragging() {
        // 松手后，变回发呆
        withAnimation {
            currentAction = .idle
        }
    }
    
    // 窗口置顶
    private func updateWindowLevel() {
        // 在所有运行的窗口中，找到那个类型是 `PetWindow` 的主窗口
        if let petWindow = NSApp.windows.first(where: { $0 is PetWindow }) {
            petWindow.level = isAlwaysOnTop ? .statusBar : .normal
            print("窗口层级已更新为: \(isAlwaysOnTop ? "置顶" : "普通")")
        }
    }
}
