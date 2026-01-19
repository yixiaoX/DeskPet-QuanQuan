//
//  RandomEventWindowManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/18/26.
//

import SwiftUI
import AppKit

@MainActor
class RandomEventWindowManager {
    static let shared = RandomEventWindowManager()
    
    private var window: NSWindow?
    
    func show() {
        // 1. 如果窗口已存在，直接激活
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 2. 创建新窗口
        // 使用与 GameWindow 类似的无边框配置
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 3. 配置窗口属性
        newWindow.isReleasedWhenClosed = false
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.hasShadow = false
        newWindow.isMovableByWindowBackground = true
        newWindow.level = .floating // 悬浮置顶，防止被宠物挡住
        newWindow.center()
        
        // 4. 创建视图
        // 传入 close 闭包，让 View 内部可以调用 Manager 的 close 方法
        let contentView = RandomEventView(onCloseWindow: {
            self.close()
        })
        
        newWindow.contentView = NSHostingView(rootView: contentView)
        
        // 5. 显示
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = newWindow
    }
    
    func close() {
        window?.close()
        window = nil
    }
}
