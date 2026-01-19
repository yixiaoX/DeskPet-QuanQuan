//
//  ClipboardService.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/14/26.
//

import AppKit

class ClipboardService {
    static let shared = ClipboardService()
    
    private let pasteboard = NSPasteboard.general
    // 记录上一次的变更计数
    private var lastChangeCount: Int
    
    init() {
        self.lastChangeCount = pasteboard.changeCount
    }
    
    /// 同步当前的变更计数（在开始监听时调用，忽略之前的旧内容）
    func syncChangeCount() {
        self.lastChangeCount = pasteboard.changeCount
    }
    
    /// 检查是否有新的文本内容
    /// Returns: (是否是新的, 文本内容)
    func fetchNewTextContent() -> (Bool, String?) {
        // 1. 检查计数器是否变化
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else {
            return (false, nil)
        }
        
        // 2. 更新计数器
        lastChangeCount = currentCount
        
        // 3. 尝试读取文本
        guard let content = pasteboard.string(forType: .string),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (false, nil)
        }
        
        return (true, content)
    }
}
