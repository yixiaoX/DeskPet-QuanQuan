//
//  GlassyWindowContainer.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/17/26.
//

import SwiftUI

/// 一个通用的、带毛玻璃效果和关闭按钮的窗口容器
struct GlassyWindowContainer<Content: View>: View {
    let content: Content
    let onClose: () -> Void
    
    // 自定义尺寸（可选）
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    
    init(width: CGFloat? = nil, height: CGFloat? = nil, onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.width = width
        self.height = height
        self.onClose = onClose
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 1. 注入的内容
            content
            
            // 2. 统一的左上角关闭按钮
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(width: 20, height: 20)
                    .background(Color.white.opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(10) // 统一边距
        }
        // --- 统一的视觉样式 ---
        .background(Material.regular) // 毛玻璃
        .cornerRadius(20)             // 大圆角
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.3), lineWidth: 1) // 边缘高光
        )
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5) // 柔和阴影
        .padding(20) // 给阴影留出外边距
        // 如果指定了大小，就强制固定；否则自适应
        .frame(width: width, height: height)
    }
}
