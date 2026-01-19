//
//  RockPaperScissorsGame.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/17/26.
//

import SwiftUI

struct RockPaperScissorsGame: View {
    @ObservedObject var petViewModel = PetViewModel()
    
    @AppStorage("pet_name") private var petName = "泉泉"
    
    let options = ["✊", "✌️", "✋"]
    @State private var petChoice = "❓"
    @State private var resultMessage = "准备开始"
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // 宠物出拳展示区
            VStack {
                Text("\(petName)出")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(petChoice)
                    .font(.system(size: 60))
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(isAnimating ? .easeInOut(duration: 0.1).repeatForever() : .default, value: isAnimating)
            }
            
            // 结果提示
            Text(resultMessage)
                .font(.headline)
                .foregroundColor(.blue)
                // 保持文字高度防止跳动
                .frame(height: 24)
            
            // 玩家选择区
            HStack(spacing: 20) {
                ForEach(options, id: \.self) { sign in
                    Button(action: { playGame(playerSign: sign) }) {
                        Text(sign)
                            .font(.system(size: 40))
                            .frame(width: 60, height: 60)
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(isAnimating) // 动画时禁止点击
                }
            }
        }
    }
    
    func playGame(playerSign: String) {
        isAnimating = true
        resultMessage = "出拳中..."
        
        // 使用 Timer 切换图标
        var runCount = 0
        
        // 模拟思考延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isAnimating = false
            let randomSign = options.randomElement()!
            petChoice = randomSign
            
            // 创建一个每 0.05 秒触发一次的定时器
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                // 每次触发都随机显示一个手势 (产生滚动的视觉效果)
                petChoice = options.randomElement()!
                runCount += 1
                
                // 滚动约 1 秒后停止 (0.05 * 20 = 1s)
                if runCount >= 20 {
                    timer.invalidate() // 销毁定时器
                    
                    // 停止动画状态
                    isAnimating = false
                    
                    // 确定最终结果
                    let finalSign = options.randomElement()!
                    petChoice = finalSign
                    
                    // 进行胜负判定
                    determineWinner(playerSign: playerSign, computerSign: finalSign)
                }
            }
        }
    }
    
    func determineWinner(playerSign: String, computerSign: String) {
        if playerSign == computerSign {
            resultMessage = "平局！再来！"
            petViewModel.gameResult(action: .idle, msg: "我也是 \(computerSign)！这叫心有灵犀吗？", duration: 5)
        } else if (playerSign == "✊" && computerSign == "✌️") ||
                  (playerSign == "✌️" && computerSign == "✋") ||
                  (playerSign == "✋" && computerSign == "✊") {
            resultMessage = "你赢啦！🎉"
            petViewModel.gameResult(action: .sad, msg: "呜呜，你出的 \(playerSign) 赢过了我的 \(computerSign) ...", duration: 5)
        } else {
            resultMessage = "\(petName)赢了 😝"
            petViewModel.gameResult(action: .happy, msg: "嘿嘿！我的 \(computerSign) 赢过你啦！", duration: 5)
        }
    }
}
