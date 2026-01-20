//
//  PetContextMenu.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import SwiftUI

struct PetContextMenu: View {
    // 接收外部传入的方法，这样菜单只负责显示，不负责具体逻辑实现（解耦）
    @ObservedObject var viewModel = PetViewModel()
    @ObservedObject var focusManager = FocusManager.shared
    
    @Environment(\.openSettings) private var openSettings
    
    @AppStorage("pet_name") private var petName = "泉泉"
    
    var body: some View {
        // Section 1: 常用功能
        
        if !viewModel.bubbleManager.isInputPermanent {
            Button(action: {
                viewModel.enableInput()
            }) {
                Label("陪我聊聊", systemImage: "message.fill")
            }
        }
        
        Toggle(isOn: Binding(
            get: { viewModel.isAutoListening },
            set: { _ in viewModel.toggleMusicListening() }
        )) {
            Label("一起听歌", systemImage: "music.note.list")
        }
        
        Toggle(isOn: Binding(
            get: { viewModel.isReading },
            set: { _ in viewModel.toggleBookReading() }
        )) {
            Label("一起看书", systemImage: "book")
        }
        
        Button(action: {
            viewModel.openStore()
        }) { //
            Label("喂食商店", systemImage: "fork.knife")
        }
        
        Button {
            viewModel.openGameCenter()
        } label: {
            Label("陪我玩玩...", systemImage: "gamecontroller")
        }
        
        Button {
            // ✨ 1. 创建原生系统弹窗
            let alert = NSAlert()
            alert.messageText = "触发随机事件"
            alert.informativeText = "确定要让\(petName)随机出门逛逛吗？"
            alert.addButton(withTitle: "继续") // 按钮索引 1000 (.alertFirstButtonReturn)
            alert.addButton(withTitle: "取消") // 按钮索引 1001 (.alertSecondButtonReturn)
            alert.alertStyle = .informational // 或者 .warning
            
            // ✨ 2. 显示弹窗并等待用户点击
            // runModal 会阻塞当前线程直到用户点击，这在 macOS 菜单操作中是标准的做法
            let response = alert.runModal()
            
            // ✨ 3. 判断结果
            if response == .alertFirstButtonReturn {
                // 用户点了“继续”，才正式打开窗口
                RandomEventWindowManager.shared.show()
            } else {
                // 用户点了“取消”，什么都不做
                print("用户取消了随机事件")
            }
        } label: {
            Label("让\(petName)出门逛逛", systemImage: "sparkles")
        }
        
        Divider()
        
        Button {
            // 点击动作不变：始终是打开“控制台”窗口
            // 如果正在专注，打开的就是倒计时界面；如果没专注，打开的就是设置界面
            FocusWindowManager.shared.show()
        } label: {
            // ✨ 2. 根据状态动态切换图标
            if focusManager.isFocusing {
                // 状态 A: 专注中 -> 显示勾勾 ✅
                Label("专注模式 (剩余 \(formatTime(focusManager.remainingSeconds)) 分)", systemImage: "hourglass")
            } else {
                // 状态 B: 闲置 -> 显示计时器图标 ⏱️
                Label("专注模式", systemImage: "timer")
            }
        }
        
        Divider() // 测试按钮
        
        /*
        Button("🎾 长文本显示测试") {
            viewModel.interact()
        }
         
        Button("🛌 手动睡觉测试") {
             viewModel.sleep()
        } */
        
                
        // ✨ 新增按钮：测试 sad.gif
        Button("💢 批评一下（网络测试）") {
            Task{
                try await viewModel.scold()
            }
        }
        
        Divider()
        
        Toggle(isOn: $viewModel.isAlwaysOnTop) {
            Label("始终置顶", systemImage: "pin")
        }
        
        SettingsLink {
            Label("设置", systemImage: "gear")
        }
        
        /* // 兼容旧系统的设置
        Button {
            NSApp.sendAction(Selector("showSettingsWindow:"), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        } label: {
            // 这里也是用 Label
            Label("设置", systemImage: "gear")
        } */
        
        Divider()
        // Section 3: 退出
        Button(action: {
            NSApplication.shared.terminate(nil)
        }) {
            Label("退出程序", systemImage: "power")
        }
    }
    
    func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        return String(format: "%02d", minutes)
    }
}

