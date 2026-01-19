//
//  HistoryWindowManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/17/26.
//

import Foundation

import AppKit
import SwiftUI

class HistoryWindowManager {
    static let shared = HistoryWindowManager()
    
    private var window: NSWindow?
    
    func show() {
        // 1. 如果窗口已经存在，直接激活并置顶
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 2. 创建新窗口
        // 尺寸设为 600x600 或适合 HistorySettingsView 的大小
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], // 标准窗口样式
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = "" // 设置窗口标题
        newWindow.center()
        newWindow.isReleasedWhenClosed = false // ✅ 防止关闭后崩溃
        
        // 3. 设置内容
        // 直接装载 HistorySettingsView
        let contentView = HistorySettingsView()
            .frame(minWidth: 600, minHeight: 500) // 确保内容有最小尺寸
        
        newWindow.contentView = NSHostingView(rootView: contentView)
        
        // 4. 显示
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.window = newWindow
    }
    
    // 如果需要手动关闭（通常不需要，用户点 x 即可）
    func close() {
        window?.close()
        window = nil
    }
}
