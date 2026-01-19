//
//  LogWindowManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/16/26.
//

import AppKit
import SwiftUI

@MainActor
class LogWindowManager {
    static let shared = LogWindowManager()
    
    private var logWindow: NSWindow?
    
    // 定义窗口大小，方便复用计算
    private let windowSize = CGSize(width: 380, height: 400)
    
    func show() {
        if let window = logWindow {
            window.makeKeyAndOrderFront(nil)
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            return
        }
        
        // 创建新窗口
        let newWindow = LogWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.borderless], // 无边框
            backing: .buffered,
            defer: false
        )
        
        // 防止窗口关闭后内存被释放导致崩溃
        newWindow.isReleasedWhenClosed = false
        
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.level = .floating // 浮动在上方，但比气泡低一点也可以
        newWindow.hasShadow = false
        newWindow.isMovableByWindowBackground = true // 允许拖拽背景移动
        newWindow.center()
        
        // 计算相对位置
        positionWindowRelativeToMain(newWindow)
        
        // 设置 ContentView
        let contentView = LogView()
        newWindow.contentView = NSHostingView(rootView: contentView)
        
        // 显示
        newWindow.makeKeyAndOrderFront(nil)
        self.logWindow = newWindow
    }
    
    func close() {
        if let logWindow = NSApp.windows.first(where: { $0 is LogWindow }) {
            logWindow.close()
        } else {
            // 保底逻辑：如果找不到名字，尝试关闭包含当前 View 的窗口
            NSApp.keyWindow?.close()
        }
    }
    
    // 专门负责定位 PetWindow 主窗口的辅助函数
    private func positionWindowRelativeToMain(_ targetWindow: NSWindow) {
        // 尝试找到主窗口 (遍历所有窗口找类型为 PetWindow 的)
        // 注意：PetWindow 类是在 AppDelegate.swift 里定义的，这里能直接访问
        if let mainWin = NSApp.windows.first(where: { $0 is PetWindow }) {
            let mainFrame = mainWin.frame
            
            // 计算 X 轴：
            // 在主窗口的左边 (minX) - Log窗口的宽度 - 间距 (比如 20)
            let targetX = mainFrame.minX - windowSize.width - 20
            
            // 计算 Y 轴：
            // "高度高出一些" -> 在 macOS 坐标系中，Y 越大越靠上。
            // 我们可以让 Log 窗口的底部 (minY) 比主窗口的底部高出 100pt
            let targetY = mainFrame.minY + 100
            
            targetWindow.setFrameOrigin(NSPoint(x: targetX, y: targetY))
        } else {
            // 如果找不到主窗口（极少见），就默认居中
            targetWindow.center()
        }
    }
}
