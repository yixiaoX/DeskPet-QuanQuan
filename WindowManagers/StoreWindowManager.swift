//
//  StoreWindowManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/15/26.
//

import SwiftUI
import AppKit

@MainActor // 确保所有窗口操作都在主线程
class StoreWindowManager {
    static let shared = StoreWindowManager()
    private var storeWindow: NSWindow?
    
    // 打开商店窗口，需要传入 ViewModel 以便绑定按钮事件
    func openStore(with petViewModel: PetViewModel) {
        // 1. 防止重复创建
        if let window = storeWindow {
            window.makeKeyAndOrderFront(nil)
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            return
        }
        
        // 2. 创建 View，注入外部传入的 PetViewModel
        // 注意：这里需要 FoodStoreView 支持接收 petViewModel 参数
        let storeView = FoodStoreView(petViewModel: petViewModel)
            .background(Color.clear)
        
        // 3. 包装成 NSWindow
        let controller = NSHostingController(rootView: storeView)
        controller.view.layer?.backgroundColor = NSColor.clear.cgColor
        
        let window = FoodWindow(contentViewController: controller) // AppDelegate 中定义的 Window 类
        window.title = "美食商店"
        window.setContentSize(NSSize(width: 540, height: 500)) // 匹配 View 的尺寸
        window.level = .floating
        
        // 4. 无边框气泡样式设置
        window.styleMask = [.borderless, .fullSizeContentView]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isMovableByWindowBackground = true
        
        // 5. 监听关闭以释放引用
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: nil) { [weak self] _ in
            self?.storeWindow = nil
        }
        
        // 6. 显示
        window.makeKeyAndOrderFront(nil)
        self.storeWindow = window
    }
}
