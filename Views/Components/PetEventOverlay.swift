//
//  PetEventOverlay.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/18/26.
//  用于处理主视图的点击和拖拽动作

import SwiftUI

@MainActor
struct PetEventOverlay: NSViewRepresentable {
    // 外部传入的回调
    var onTap: () -> Void
    var onDragStart: () -> Void
    var onDragEnd: () -> Void
    
    func makeNSView(context: Context) -> EventListeningView {
        let view = EventListeningView()
        view.onTap = onTap
        view.onDragStart = onDragStart
        view.onDragEnd = onDragEnd
        return view
    }
    
    func updateNSView(_ nsView: EventListeningView, context: Context) {
        // 更新回调，防止闭包捕获旧的 State
        nsView.onTap = onTap
        nsView.onDragStart = onDragStart
        nsView.onDragEnd = onDragEnd
    }
    
    // 内部类：处理 AppKit 底层事件
    class EventListeningView: NSView {
        var onTap: (() -> Void)?
        var onDragStart: (() -> Void)?
        var onDragEnd: (() -> Void)?
        
        // 记录鼠标按下时，光标相对于窗口左下角的偏移量
        private var initialOffset: NSPoint?
        private var isDragging = false
        
        // 1. 核心：允许非激活状态下的点击穿透
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            return true
        }
        
        override func mouseDown(with event: NSEvent) {
            // 记录初始状态
            self.isDragging = false
            self.initialOffset = event.locationInWindow // 比如鼠标在窗口内的 (50, 50)
            
            // 通知 ViewModel (比如改变表情)
            onDragStart?()
        }
        
        override func mouseDragged(with event: NSEvent) {
            guard let window = self.window,
                  let offset = initialOffset else { return }
            
            // 标记为正在拖拽，这样松手时就不会触发点击
            self.isDragging = true
            
            // 2. 计算新坐标
            // 公式：当前屏幕鼠标位置 - 初始点击在窗口内的偏移量
            let currentLocation = NSEvent.mouseLocation
            let newOrigin = NSPoint(
                x: currentLocation.x - offset.x,
                y: currentLocation.y - offset.y
            )
            
            // 3. 移动窗口
            window.setFrameOrigin(newOrigin)
        }
        
        override func mouseUp(with event: NSEvent) {
            onDragEnd?()
            
            // 4. 只有在没有发生拖拽的情况下，才认为是“点击”
            if !isDragging {
                onTap?()
            }
            
            // 重置状态
            initialOffset = nil
            isDragging = false
        }
    }
}
