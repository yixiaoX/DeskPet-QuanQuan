//
//  GameWindowManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/17/26.
//

import AppKit
import SwiftUI

class GameWindowManager {
    static let shared = GameWindowManager()
    
    private var window: NSWindow?
    private let windowSize = CGSize(width: 320, height: 400) // 游戏窗口稍微窄一点
    
    func show(with petViewModel: PetViewModel) {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        let newWindow = GameWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.borderless], // 无边框
            backing: .buffered,
            defer: false
        )
        
        newWindow.isReleasedWhenClosed = false
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.level = .floating
        newWindow.hasShadow = false
        newWindow.isMovableByWindowBackground = true
        newWindow.center()
        
        let contentView = GameCenterView(petViewModel: petViewModel)
        newWindow.contentView = NSHostingView(rootView: contentView)
        
        newWindow.makeKeyAndOrderFront(nil)
        self.window = newWindow
    }
    
    func close() {
        if let logWindow = NSApp.windows.first(where: { $0 is GameWindow }) {
            logWindow.close()
        } else {
            // 保底逻辑：如果找不到名字，尝试关闭包含当前 View 的窗口
        }
    }
}
