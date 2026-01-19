//
//  FocusWindowManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/18/26.
//

import Foundation

import SwiftUI
import AppKit

@MainActor
class FocusWindowManager {
    static let shared = FocusWindowManager()
    
    private var window: NSWindow?
    
    func show() {
        // 如果窗口已存在，置顶
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 创建一个小巧的无边框窗口
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 360), // 尺寸设小一点
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        newWindow.isReleasedWhenClosed = false
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.hasShadow = false
        newWindow.isMovableByWindowBackground = true
        newWindow.level = .floating // 悬浮置顶
        newWindow.center()
        
        let contentView = FocusStartView(onClose: {
            self.close()
        })
        
        newWindow.contentView = NSHostingView(rootView: contentView)
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = newWindow
    }
    
    func close() {
        window?.close()
        window = nil
    }
}
