//
//  DiceGame.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/17/26.
//

import SwiftUI

struct DiceGame: View {
    @ObservedObject var petViewModel = PetViewModel()
    
    @AppStorage("pet_name") private var petName = "泉泉"
    
    @State private var playerDice = 1
    @State private var petDice = 1
    
    @State private var isRolling = false
    @State private var resultMessage = "比比谁大"
    
    @State private var centerSymbol = "VS"
    
    var body: some View {
        VStack(spacing: 30) {
            
            // --- 骰子显示区 ---
            HStack(spacing: 40) {
                // 宠物 (左)
                VStack(spacing: 10) {
                    Text("\(petName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "die.face.\(petDice).fill")
                        .resizable()
                        .foregroundStyle(isRolling ? .gray : .orange) // 滚动时灰色，定格时橙色
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isRolling ? 15 : 0))
                }
                
                // VS 标志
                Text(centerSymbol)
                    .font(.system(size: 30, weight: .heavy, design: .rounded)) // 稍微调大了一点
                    .foregroundColor(centerSymbol == "VS" ? .gray.opacity(0.5) : .primary) // VS 时灰色，出结果时变亮
                    .offset(y: 10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: centerSymbol) // 符号变化时的弹跳动画
                    .contentTransition(.numericText())
                
                // 玩家 (右)
                VStack(spacing: 10) {
                    Text("你")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "die.face.\(playerDice).fill")
                        .resizable()
                        .foregroundStyle(isRolling ? .gray : .blue) // 滚动时灰色，定格时蓝色
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isRolling ? -15 : 0)) // 轻微晃动动画
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: playerDice) // 数字变化时的弹跳感
            
            // --- 结果提示 ---
            Text(resultMessage)
                .font(.headline)
                .foregroundColor(.primary)
                .frame(height: 24) // 占位防跳动
            
            // --- 按钮 ---
            Button(action: startRolling) {
                Text(isRolling ? "🎲 激战中..." : "掷骰子")
                    .font(.headline)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 10)
                    .background(isRolling ? Color.gray.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 2)
            }
            .buttonStyle(.plain)
            .disabled(isRolling)
        }
    }
    
    // MARK: - 游戏逻辑
    func startRolling() {
        isRolling = true
        resultMessage = "咕噜咕噜..."
        centerSymbol = "VS" // ✨ 开始滚动时，重置回 VS
        
        var runCount = 0
        
        // 使用定时器制造滚动效果 (0.1秒变一次)
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            // 滚动期间显示随机数
            playerDice = Int.random(in: 1...6)
            petDice = Int.random(in: 1...6)
            runCount += 1
            
            // 滚动 10 次后停止 (约1秒)
            if runCount >= 10 {
                timer.invalidate()
                finishGame()
            }
        }
    }
    
    func finishGame() {
        isRolling = false
        
        // 生成最终结果
        let finalPlayer = Int.random(in: 1...6)
        let finalPet = Int.random(in: 1...6)
        
        playerDice = finalPlayer
        petDice = finalPet
        
        if finalPet < finalPlayer {
            centerSymbol = "<"
            resultMessage = "你赢了！"
            
            let loseMsgs = ["不公平！你肯定作弊了！", "下次我绝对会掷出6点的！", "哼，你运气真好，算你赢了！"]
            petViewModel.gameResult(action: .sad, msg: loseMsgs.randomElement()!, duration: 5)
            
        } else if finalPet > finalPlayer {
            centerSymbol = ">"
            resultMessage = "\(petName)赢了！"
            
            let winMsgs = ["哈哈！我掷得更高，我赢了！", "嘿嘿，下次一定让着你！", "赢了有奖励吗？"]
            petViewModel.gameResult(action: .happy, msg: winMsgs.randomElement()!, duration: 5)
            
        } else {
            centerSymbol = "="
            resultMessage = "平局！"
            petViewModel.gameResult(action: .idle, msg: "竟然打平了，再来一局？", duration: 5)
        }
    }
}
