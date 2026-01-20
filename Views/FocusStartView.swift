//
//  FocusStartView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/18/26.
//

import SwiftUI

struct FocusStartView: View {
    // 监听全局专注状态
    @ObservedObject var focusManager = FocusManager.shared
    
    // 设置
    @AppStorage("focus_default_duration") private var savedDuration: Double = 25
    
    // 临时的时长状态
    @State private var currentDuration: Double = 25
    
    // 关闭窗口的回调
    var onClose: () -> Void
    
    var body: some View {
        GlassyWindowContainer(width: 320, height: nil, onClose: onClose) {
            VStack {
                // 标题栏
                HStack {
                    Spacer()
                    Image(systemName: focusManager.isFocusing ? "timer" : "slider.horizontal.3")
                        .foregroundColor(focusManager.isFocusing ? .blue : .purple)
                    
                    Text(focusManager.isFocusing ? "专注进行中" : "准备专注")
                        .font(.headline)
                    
                    Spacer()
                }
                .padding(.bottom, 10)
                
                Divider()
                
                // ✨✨✨ 状态切换区域 ✨✨✨
                ZStack {
                    if focusManager.isFocusing {
                        // MARK: - 状态 B: 专注中 (计时器 + 停止按钮)
                        runningView
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        // MARK: - 状态 A: 设置页 (滑块 + 开始按钮)
                        setupView
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: focusManager.isFocusing)
            }
            .padding(20)
        }
        .onAppear {
            if !focusManager.isFocusing {
                currentDuration = savedDuration
            }
        }
    }
    
    // MARK: - 子视图：设置界面
    var setupView: some View {
        VStack(spacing: 25) {
            Spacer().frame(height: 10)
            
            // 大数字显示
            Text("\(Int(currentDuration)) 分钟")
                .font(.system(size: 48, weight: .heavy))
                .monospacedDigit()
                .foregroundColor(.primary)
                .contentTransition(.numericText())
            
            // 滑块
            VStack(spacing: 5) {
                Slider(value: $currentDuration, in: 5...120, step: 5)
                    .tint(.purple)
                
                HStack {
                    Text("5m").font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Text("120m").font(.caption2).foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 启动按钮
            Button(action: startFocus) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("开始计时")
                }
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
                .shadow(color: .purple.opacity(0.4), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - 子视图：运行界面
    var runningView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 10)
            
            // 倒计时圆环
            ZStack {
                // 底环
                Circle()
                    .stroke(lineWidth: 12)
                    .opacity(0.1)
                    .foregroundColor(.blue)
                
                // 进度环
                Circle()
                    .trim(from: 0.0, to: CGFloat(focusManager.progress))
                    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.blue)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear(duration: 1.0), value: focusManager.progress)
                
                // 剩余时间文字
                VStack(spacing: 4) {
                    Text(formatTime(focusManager.remainingSeconds))
                        .font(.system(size: 36, weight: .bold))
                        .monospacedDigit()
                    
                    Text("剩余时间")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150, height: 150)
            
            Spacer()
            
            // 停止按钮
            Button(action: stopFocus) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("放弃专注 (无奖励)")
                }
                .fontWeight(.medium)
                .foregroundColor(.red.opacity(0.8))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.red.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - 逻辑方法
    
    func startFocus() {
        let blacklist = UserDefaults.standard.stringArray(forKey: "focus_blacklist") ?? []
        print("启动专注，黑名单为: \(blacklist)")
        // 启动！(View 会自动监听到 isFocusing 变 true 而切换 UI)
        focusManager.startFocus(minutes: Int(currentDuration), keywords: blacklist)
    }
    
    func stopFocus() {
        // 停止！(View 会自动监听到 isFocusing 变 false 而切换回设置页)
        focusManager.stopFocus(isCompleted: false)
    }
    
    func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
