//
//  InteractionManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/14/26.
//

import Foundation
import Combine

class InteractionManager {
    // 依赖
    private let chatService = ChatService.shared
    private let historyManager = HistoryManager.shared
    private var defaults: UserDefaults { UserDefaults.standard }
    
    private var petCall: String { defaults.string(forKey: "pet_call_user") ?? "主人" }
    
    // --- 状态记录 ---
    private var lastInteractionTime: Date = Date() // 上次互动时间
    private let sleepThreshold: TimeInterval = 20 * 60  // 20 分钟 (单位: 秒)
    private let idleMessageThreshold: TimeInterval =  10 * 60 // 10 分钟
    
    private var isBoring = false    // 用于判断是否后台发送闲置信息
    
    // --- 定时器 ---
    private var randomActionTimer: Timer? // 短期随机动作
    private var sleepCheckTimer: Timer?  // 长期睡眠检查
    
    // --- 回调 ---
    // (动作, 气泡文字, 持续时间)
    var onRequestAction: ((PetAction, String, TimeInterval) -> Void)?
    
    init() {
        startTimers()
    }
    
    // MARK: - 计时器设置
    
    func startTimers() {
        // 1. 启动短时间随机动作循环 (比如偶尔伸个懒腰，但不说话)
        // scheduleNextRandomAction()
        
        // 2. 启动睡眠检查 (每5分钟检查一次是否该睡觉了)
        sleepCheckTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            Task { [weak self] in
                guard let self else { return }
                try? await self.checkIfShouldSleep()
            }
        }
    }
    
    func stopTimers() {
        randomActionTimer?.invalidate()
        sleepCheckTimer?.invalidate()
    }
    
    // 用户产生交互时调用此方法 (重置计时器)
    func recordInteraction() {
        lastInteractionTime = Date()
        isBoring = false
    }
    
    // MARK: - 闲置自动发送消息和睡眠检查
    private func checkIfShouldSleep() async throws {
        // 如果 10 分钟没理他，后台发送信息；超过 20 分钟没理她了，开始打盹；25 分钟开始睡觉
        if Date().timeIntervalSince(lastInteractionTime) >= sleepThreshold + 5 * 60 {
            // 睡觉 (持续时间为 0，代表一直睡，直到被叫醒)
            onRequestAction?(.keepSleeping, "", 0)
        } else if Date().timeIntervalSince(lastInteractionTime) >= sleepThreshold {
            // 打盹
            onRequestAction?(.sleeping, "呼...好困呀...💤", 0)
        } else if Date().timeIntervalSince(lastInteractionTime) >= idleMessageThreshold && !isBoring {
            isBoring = true
            // 后台自动向 AI 发送一条请求
            let interact = "\(petCall)很久没有理你了。你现在无聊得快睡着了。你要自言自语说句关心的话。"
            let reply = try await chatService.interactReply(interaction: interact)
            historyManager.addMessage(role: .ai, content: "🥱 [无聊] \(reply)")
            onRequestAction?(.sleeping, reply, 20)
        }
    }
    
    // MARK: - 🎲 短期随机动作 (保留接口)
    
    private func scheduleNextRandomAction() {
        // 随机 60~120 秒触发一次
        let randomInterval = Double.random(in: 60...120)
        
        randomActionTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { [weak self] _ in
            // self?.triggerRandomAction()
            self?.scheduleNextRandomAction() // 递归调用，保持循环
        }
    }
    
    private func triggerRandomAction() {
        // ⚠️ 只有在活跃时间（没睡觉）才触发随机动作
        let isSleeping = Date().timeIntervalSince(lastInteractionTime) >= sleepThreshold
        if isSleeping { return }
        
        // 这里是你想要的“短时间随机动作接口”
        // 目前我们不让它 speak，而是做一些无声动作
        // 如果你有 stretch.gif (伸懒腰) 或 look_around.gif (看风景) 就在这里用
        
        let randomAction = Bool.random() ? PetAction.eating : PetAction.sleeping
        // 只是简单的动一下，或者心里想一件事（不张嘴说话）
        // 比如：happy 动作 + "（哼着小曲...）"
        
        // 如果你希望它完全静默，只做动作，text 可以传空字符串 ""
        onRequestAction?(randomAction, "", 5)
    }
    
    
    // MARK: - 👋 具体的交互方法
    
    // 投喂
    /*
    func feed() -> (action: PetAction, msg: String, duration: TimeInterval) {
        return (.eating, "阿姆阿姆...好吃！", 5.0)
    }
     */
    func feed(_ food: String) async throws -> (action: PetAction, msg: String, duration: TimeInterval) {
        recordInteraction()
        onRequestAction?(.eating, "正在大口吃\(food)...", 5)
        let feeding = "\(petCall)刚刚给你投喂了一份\(food)。请以第一人称表现出吃完后的感想。"
        let reply = try await chatService.interactReply(interaction: feeding) // 互动行为：\(feeding)
        historyManager.addMessage(role: .ai, content: "🍪 [被投喂了] \(reply)")
        try await Task.sleep(for: .milliseconds(2500))  // 异步任务挂起 2.5 秒，等待宠物吃完
        return (.speaking, reply, 5)
    }
    
    func focusCompleted(_ reward: Int) async throws -> (action: PetAction, msg: String, duration: TimeInterval) {
        let event = "\(petCall)圆满完成了专注任务！请夸奖\(petCall)，并提到你已经奖励了 \(reward) 金币。"
        let reply = try await chatService.interactReply(interaction: event)
        historyManager.addMessage(role: .ai, content: "🎉 \(reply)")
        return (.happy, reply, 5)
    }
    
    // MARK: - 功能测试函数
    
    // 睡觉 (手动触发)
    func sleep() -> (action: PetAction, msg: String, duration: TimeInterval) {
        // 手动睡觉不更新 lastInteractionTime，让她直接睡
        return (.sleeping, "晚安...", 0)
    }
    
    // 互动 (长文本测试)
    func interact() -> (action: PetAction, msg: String, duration: TimeInterval) {
        recordInteraction() // 记为一次交互
        let reply = "这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋这是什么🤔吃一口😋"
        return (.happy, reply, 5)
    }
    
    // 批评
    func scold() async throws -> (action: PetAction, msg: String, duration: TimeInterval) {
        recordInteraction()
        let interact = "\(petCall)批评了你"
        let reply = try await chatService.interactReply(interaction: interact)
        historyManager.addMessage(role: .ai, content: "😫 [被批评了] \(reply)")
        return (.sad, reply, 12)
    }
}
