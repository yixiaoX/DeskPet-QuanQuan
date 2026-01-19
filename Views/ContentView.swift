//
//  ContentView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import SwiftUI
import SDWebImageSwiftUI

@MainActor
struct ContentView: View {
    // 引入 ViewModel (大脑)
    // @StateObject 意味着：这个 View 拥有这个大脑的生命周期
    @StateObject private var viewModel = PetViewModel()

    
    var body: some View {
        // 1. 气泡和宠物本体渲染，用 ZStack 并强制底部对齐
        VStack(spacing: 0) {
            Spacer()    //将宠物置于透明窗口的底部
            // --- 气泡层 ---
            BubbleView(
                text: viewModel.bubbleManager.text,
                isInputMode: viewModel.bubbleManager.shouldShowInput,        // 绑定状态
                inputText: $viewModel.bubbleManager.userInput,         // 绑定输入内容
                onCommit: { viewModel.commitChat() },    // 绑定回车事件
                onTapText: {
                    // 点击气泡逻辑
                    if viewModel.bubbleManager.isTyping {
                        // 如果文字正在逐字显示，点击直接显示全文
                        viewModel.bubbleManager.skipTyping()
                    } else if viewModel.bubbleManager.shouldShowInput {
                        withAnimation {
                            viewModel.bubbleManager.closeBubble()
                        }
                    } else {
                        viewModel.enableInput()
                    }
                },
                onDragStart: { viewModel.startDragging() },
                onDragEnd: { viewModel.endDragging() }
            )
            .padding(.bottom, 10) // 气泡和宠物间隙 10
            // .border(.blue) // 🔵 蓝色框：气泡的实际范围
            .opacity(viewModel.bubbleManager.shouldShowContainer ? 1 : 0) // 👁️ 核心：只改变透明度，不改变布局大小
            .animation(.spring(), value: viewModel.showBubble) // 加个淡入淡出动画
            // 让透明的气泡不拦截鼠标点击，直接穿透到后面
            .allowsHitTesting(viewModel.bubbleManager.shouldShowContainer)
            
            
            // --- 宠物层 (永远在最底部) ---
            PetAvatarView(
                imageName: viewModel.currentAction.gifName
            )
            .frame(width: 200, height: 200)
            // 保持层级最高
            .zIndex(1)
            
            .overlay(
                PetEventOverlay(
                    onTap: {
                        // 这里放原本的点击逻辑
                        if viewModel.bubbleManager.isTyping {
                            // 如果文字正在逐字显示，点击直接显示全文
                            viewModel.bubbleManager.skipTyping()
                        } else if viewModel.bubbleManager.isBubbleVisible {
                            // 如果气泡文本区域开着，点击宠物关闭气泡（常驻模式关闭文本区域）
                            withAnimation { viewModel.bubbleManager.closeBubble() }
                        } else {
                            // 情况B：如果气泡没显示，才开始新的互动
                            viewModel.enableInput()
                        }
                    },
                    onDragStart: {
                        viewModel.startDragging()
                    },
                    onDragEnd: {
                        viewModel.endDragging()
                    }
                )
            )
            // .border(.red)  // 🔴 红色框：宠物的实际范围
            .background(Color.clear)
            
            // 生成右键菜单
            .contextMenu {
                PetContextMenu(viewModel: viewModel)
            }
        }
    }
}
