//
//  RandomEventViewModel.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/18/26.
//

import SwiftUI
import Combine

// 选项的数据结构
struct EventOption: Identifiable {
    let id = UUID()
    let text: String
    let moodChange: Int
    let coinsChange: Int
}

// 解析后的事件数据结构
struct RandomEventData {
    let description: String
    let options: [EventOption]
}

@MainActor
class RandomEventViewModel: ObservableObject {
    @AppStorage("user_name") private var userName = "用户"
    
    @Published var isLoading = false
    @Published var eventData: RandomEventData? = nil
    @Published var rawErrorText: String? = nil // 解析失败时显示的原始内容
    
    // 结果弹窗控制
    @Published var showResultAlert = false
    @Published var resultMessage = ""
    
    private let chatService = ChatService.shared
    private let statsManager = StatsManager.shared
    
    // 开始生成事件
    func generateEvent() {
        isLoading = true
        rawErrorText = nil
        eventData = nil
        
        Task {
            do {
                let response = try await chatService.randomEvent()
                parseEvent(response)
            } catch {
                rawErrorText = "生成失败：\(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // 解析 AI 返回的格式字符串
    // 格式：描述|A文字|A心情,A金币|B文字|B心情,B金币|C文字|C心情,C金币
    private func parseEvent(_ raw: String) {
        let parts = raw.split(separator: "|").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // 校验部分数量：1个描述 + 3个选项 * 2部分(文字+数值) = 7 部分
        guard parts.count >= 7 else {
            print("解析失败：格式不对，部分数量为 \(parts.count)")
            self.rawErrorText = raw
            self.isLoading = false
            return
        }
        
        let description = parts[0]
        var options: [EventOption] = []
        
        // 解析三个选项 (索引 1,2 | 3,4 | 5,6)
        for i in 0..<3 {
            let textIndex = 1 + i * 2
            let valueIndex = 2 + i * 2
            
            if valueIndex < parts.count {
                let optionText = parts[textIndex]
                let values = parts[valueIndex].split(separator: ",").map { String($0) }
                
                if values.count == 2,
                   let mood = Int(values[0]),
                   let coins = Int(values[1]) {
                    options.append(EventOption(text: optionText, moodChange: mood, coinsChange: coins))
                }
            }
        }
        
        if options.count == 3 {
            self.eventData = RandomEventData(description: description, options: options)
        } else {
            self.rawErrorText = raw
        }
        
        self.isLoading = false
    }
    
    // 用户选择某个选项
    func selectOption(_ option: EventOption) {
        // 1. 更新数据
        if option.moodChange != 0 {
            if option.moodChange > 0 {
                statsManager.increaseMood(amount: option.moodChange)
            } else {
                statsManager.decreaseMood(amount: abs(option.moodChange))
            }
        }
        
        if option.coinsChange != 0 {
            if option.coinsChange > 0 {
                statsManager.coins += option.coinsChange // 直接加
            } else {
                _ = statsManager.trySpendCoins(amount: abs(option.coinsChange))
            }
        }
        
        // 2. 准备弹窗文案
        var resultStrs: [String] = []
        if option.moodChange != 0 {
            resultStrs.append("心情 \(option.moodChange > 0 ? "+" : "")\(option.moodChange)")
        }
        if option.coinsChange != 0 {
            resultStrs.append("金币 \(option.coinsChange > 0 ? "+" : "")\(option.coinsChange)")
        }
        
        let changeText = resultStrs.isEmpty ? "无事发生" : resultStrs.joined(separator: "，")
        resultMessage = "你选择\n\(option.text)\n结果：\(changeText)"
        
        // 3. 显示弹窗
        showResultAlert = true
        
        // 4. 保存记录
        let historyLog = "🎲 [路遇记录] \(userName)选择了「\(option.text)」，结果：\(changeText)"
        Task {
            try await DatabaseService.shared.addMessage(role: .system, content: historyLog)
        }
    }
}
