//
//  BubbleView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import SwiftUI

struct BubbleView: View {
    var text: String

    var isInputMode: Bool
    @Binding var inputText: String
    var onCommit: () -> Void // 回车后的回调
    var onTapText: () -> Void  // 点击气泡的回调
    
    // ✨ 新增：接收来自父视图的拖拽回调
    var onDragStart: () -> Void = {}
    var onDragEnd: () -> Void = {}
    
    // 自动聚焦 (让输入框一出现光标就在里面)
    @FocusState private var isFocused: Bool
    
    // 动画参数
    private let animationSpec = Animation.spring(response: 0.4, dampingFraction: 0.7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. 上半部分：宠物说的话 (始终显示)
            
            if !text.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ViewThatFits(in: .vertical) {
                        // 文字数量较少时，自适应气泡高度
                        Text(text)
                            .font(.system(size: 14))
                            .fixedSize(horizontal: false, vertical: true) // 允许自动换行
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 文字较多时采用滚动视图
                        ScrollView(.vertical, showsIndicators: true) {
                            Text(text)
                                .font(.system(size: 14))
                                .fixedSize(horizontal: false, vertical: true) // 允许自动换行
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.bottom, isInputMode ? 12 : 0)
                }
                // ✨ 动画过渡：文字出现/消失时，带有滑动和透明度变化
                .transition(.move(edge: .bottom).combined(with: .opacity))
                // 点击事件
                .contentShape(Rectangle()) // 确保空白区域也能响应点击
                .allowsHitTesting(false)
            }
            
            // 2. 分割线 (仅当两者都存在时显示)
            if !text.isEmpty && isInputMode {
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.bottom, 12) // 分割线到底部的间距
                    .transition(.opacity) // 分割线只需要淡入淡出
            }
            
            // 3. 下半部分：输入区域 (只在输入模式下展开)
            if isInputMode {
                HStack(spacing: 8) {
                    // 最近对话按钮
                    Button(action: {
                        LogWindowManager.shared.show()
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("查看最近对话")
                    
                    // 输入框
                    TextField("说点什么...", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($isFocused)
                        .onSubmit(onCommit)
                    
                    // 发送按钮)
                    Button(action: onCommit) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                // ✨ 动画过渡：输入框出现时，看起来像是从上面“折叠”下来的
                .transition(
                    text.isEmpty
                    ? .move(edge: .bottom).combined(with: .opacity) // 无消息时从下弹出
                    : .move(edge: .top).combined(with: .opacity)    // 有消息时从上弹出
                )
                .onAppear {
                    // 稍微延迟一点点聚焦，配合动画
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                }
            }
        }
        // 统一内边距
        .padding(16)
        .frame(width: 260)
        
        // MARK: - 视觉效果优化
        // 应用原生毛玻璃材质
        .background {
            ZStack {
                // 1. 视觉层：毛玻璃
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.regularMaterial)
                
                // 2. 交互层：PetEventOverlay
                // 这一层铺满了整个气泡背景。
                // 因为 TextField 在上面的 VStack 里，所以 Overlay 不会盖住输入框。
                // 但它会盖住上面的 Text (因为设置了 allowsHitTesting false) 和空白处。
                PetEventOverlay(
                    onTap: onTapText,  //原本的点击回调传给这里
                    onDragStart: onDragStart,
                    onDragEnd: onDragEnd
                )
            }
        }
        
        // 增加玻璃边缘的高光描边 (关键细节)
        // 这会让气泡看起来有厚度，而不是一张纸
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.4), lineWidth: 0.5)
        )
        
        // 优化阴影：更柔和、带有轻微的向下偏移
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
        // 关键动画绑定
        // 监听这两个值的变化，触发 VStack 内部的 layout 动画
        .animation(animationSpec, value: text.isEmpty)
        .animation(animationSpec, value: isInputMode)
    }
}

// 预览一下效果
/*
#Preview {
    ZStack {
        // 弄个彩色背景模拟桌面
        Color.blue.opacity(0.2).ignoresSafeArea()
        
        BubbleView(text: "Hello, Bubble!", onClose: {})
    }
    .frame(width: 300, height: 200)
}
*/
