//
//  FocusManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/18/26.
//

import SwiftUI
import Combine

@MainActor
class FocusManager: ObservableObject {
    static let shared = FocusManager()
    
    // 状态
    @Published var isFocusing = false
    @Published var remainingSeconds = 0
    @Published var totalSeconds = 0
    @Published var progress: Double = 0.0
    
    // 设置
    private var blockedKeywords: [String] = []
    private var timer: Timer?
    private var monitorTimer: Timer?
    
    // 引用其他模块
    private let statsManager = StatsManager.shared
    
    // 防刷屏：记录上次警告时间
    private var lastWarningTime: Date?
    
    // ✨✨✨ 新增：定义一个事件类型，包含动作和文字
    enum FocusEvent {
        case warning(String)   // 警告
        case reward(Int)       // 奖励完成
        case breakFocus        // 中断
        case start(Int)        // 开始
    }
    
    // ✨✨✨ 新增：创建一个“广播电台”
    // PassthroughSubject 不会保存状态，只会把新消息发出去
    let eventSubject = PassthroughSubject<FocusEvent, Never>()
    
    // MARK: - 开始专注
    func startFocus(minutes: Int, keywords: [String]) {
        guard minutes > 0 else { return }
        
        self.totalSeconds = minutes * 60
        self.remainingSeconds = self.totalSeconds
        self.blockedKeywords = keywords
        self.isFocusing = true
        self.progress = 0.0
        
        // 1. 启动倒计时
        timer?.invalidate()
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // 防止部分窗口下计时器暂停工作
        RunLoop.main.add(newTimer, forMode: .common)
        self.timer = newTimer
        
        // 2. 启动监控 (每2秒检查一次，省电)
        monitorTimer?.invalidate()
        let newMonitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkFrontmostApp()
        }
        RunLoop.main.add(newMonitorTimer, forMode: .common)
        self.monitorTimer = newMonitorTimer
        
        eventSubject.send(.start(minutes))
    }
    
    // MARK: - 停止/完成
    func stopFocus(isCompleted: Bool) {
        timer?.invalidate()
        monitorTimer?.invalidate()
        isFocusing = false
        
        if isCompleted {
            // 发放奖励
            statsManager.coins += 20
            statsManager.increaseMood(amount: 5)
           
            eventSubject.send(.reward(20))
        } else {
            eventSubject.send(.breakFocus)
            // HistoryManager.shared.addMessage(role: .system, content: "🚫 专注已取消")
        }
    }
    
    // MARK: - 倒计时逻辑
    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            progress = Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
        } else {
            stopFocus(isCompleted: true)
        }
    }
    
    // MARK: - 监控逻辑
    private func checkFrontmostApp() {
        guard isFocusing else { return }
        
        // 获取前台应用
        if let app = NSWorkspace.shared.frontmostApplication,
           let appName = app.localizedName {
            // 🔍 调试日志 1：看看当前实际上抓取到了什么名字
            print("正在监控: 当前前台应用是 [\(appName)]")
            
            // 🔍 调试日志 2：看看黑名单里到底存了什么
            print("当前黑名单: \(blockedKeywords)")
            // 检查是否在黑名单中 (忽略大小写)
            let isBlocked = blockedKeywords.contains { keyword in
                appName.localizedCaseInsensitiveContains(keyword)
            }
            
            if isBlocked {
                triggerWarning(appName: appName)
            }
        }
    }
    
    // 修改 triggerWarning
    private func triggerWarning(appName: String) {
        if let last = lastWarningTime, Date().timeIntervalSince(last) < 10 { return }
        lastWarningTime = Date()
        
        let warningMsgs = [
            "喂！不要玩 \(appName) 啦！",
            "快回去工作！被我抓到了！",
            "说好的专注呢？把 \(appName) 关掉！"
        ]
        let msg = warningMsgs.randomElement() ?? "快回去工作！"
        
        // 1. 记录历史 (保持不变)
        // HistoryManager.shared.addMessage(role: .ai, content: "💢 [警报] \(msg)")
        
        // 2. ✨ 发送广播信号，通知 UI 层做动画
        eventSubject.send(.warning(msg))
    }
}
