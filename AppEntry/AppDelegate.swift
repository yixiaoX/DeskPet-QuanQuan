//
//  AppDelegate.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import SwiftUI
import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. 创建 UI 视图 (这里对应 ContentView)
        let contentView = ContentView()

        // 2. 创建原生窗口 (NSWindow)
        window = PetWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400), // 初始位置和大小
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel], // 无边框
            backing: .buffered,
            defer: false
        )
        
        // 3. 设置窗口属性
        window.isOpaque = false // 允许不透明度
        window.backgroundColor = .clear // 背景完全透明
        window.isMovableByWindowBackground = true // 允许按住任意地方拖动
        window.hasShadow = false    //关闭系统阴影
        
        // ✨✨✨ 核心修复：添加以下两行 ✨✨✨
        // .canJoinAllSpaces: 允许宠物出现在所有虚拟桌面上
        // .fullScreenAuxiliary: 明确允许宠物显示在全屏 App 之上 (这是关键)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        
        // 4. 设置窗口置顶
        let isTop = UserDefaults.standard.object(forKey: "isAlwaysOnTop") as? Bool ?? true // 默认置顶
        window.level = isTop ? .statusBar : .normal
        
        // 5. 加载 SwiftUI 视图
        window.contentView = PetHostingView(rootView: contentView)
        
        // 6. 让窗口显示在右下角
        if let screen = NSScreen.main {
            let visibleFrame = screen.visibleFrame // 可用区域 (会自动避开 Dock 和菜单栏)
            let windowSize = window.frame.size
            
            // 计算 X 轴 (屏幕最右边 - 窗口宽度 - 右边距)
            // 这里留 20 像素边距
            let newX = visibleFrame.maxX - windowSize.width - 20
            
            // 计算 Y 轴 (屏幕底部 + 下边距)
            // 注意：macOS 坐标原点在左下角，Y 越大越往上
            // visibleFrame.minY 通常是 Dock 栏的高度
            // 这里设置 50 像素，让它飘在 Dock 上方一点点
            let newY = visibleFrame.minY + 50
            
            // 设置位置
            window.setFrameOrigin(NSPoint(x: newX, y: newY))
        }
        
        window.makeKeyAndOrderFront(nil)
    }
}

// 自定义的 HostingView，专门用来处理点击穿透
class PetHostingView<Content: View>: NSHostingView<Content> {
    @MainActor
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true // 允许在窗口未激活时直接响应点击
    }
}

// 一个自定义的窗口类，专门用来解决无边框无法输入的问题
@MainActor
class PetWindow: NSPanel {
    // 告诉系统：我可以成为“关键窗口”（接受键盘输入）
    override var canBecomeKey: Bool {
        return true
    }
    
    // 告诉系统：我可以成为“主窗口”
    override var canBecomeMain: Bool {
        return true
    }
}

@MainActor  // 用于处理关闭按钮点击后崩溃
class FoodWindow: NSWindow {
    // 告诉系统：我可以成为“关键窗口”
    override var canBecomeKey: Bool {
        return true
    }
}

@MainActor  // 用于处理关闭按钮点击后崩溃
class GameWindow: NSWindow {
    // 告诉系统：我可以成为“关键窗口”
    override var canBecomeKey: Bool {
        return true
    }
}

@MainActor  // 用于处理关闭按钮点击后崩溃
class LogWindow: NSWindow {
}

