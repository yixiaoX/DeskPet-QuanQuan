//
//  RandomEventView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/18/26.
//

import SwiftUI

struct RandomEventView: View {
    @StateObject private var viewModel = RandomEventViewModel()
    
    @AppStorage("pet_name") private var petName = "泉泉"
    
    // 这是一个回调，用于在弹窗确认后关闭整个 RandomEventWindow
    var onCloseWindow: () -> Void
    
    @State private var window: NSWindow?
    
    var body: some View {
        GlassyWindowContainer(width: 500, height: nil, onClose: onCloseWindow) {
            ZStack {
                VStack(spacing: 20) {
                    
                    // 标题
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                        Text("\(petName)的奇遇记")
                            .font(.headline)
                    }
                    // .padding(.top, 10)
                    
                    Divider()
                    
                    if viewModel.isLoading {
                        // --- 加载状态 ---
                        VStack(spacing: 15) {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("\(petName)正在推门出去寻找奇遇...")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else if let errorText = viewModel.rawErrorText {
                        // --- 解析失败 (显示原始内容) ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("发生了一点意外，收到原始信息：")
                                .font(.caption)
                                .foregroundColor(.red)
                            
                            ScrollView {
                                Text(errorText)
                                    .font(.body)
                                    .padding()
                            }
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(8)
                        }
                        .padding()
                    } else if let data = viewModel.eventData {
                        // --- 成功状态 ---
                        
                        // 1. 描述文字
                        Text(data.description)
                            .font(.system(size: 15))
                            .lineSpacing(4)
                            .lineLimit(nil)
                            .padding(.horizontal, 5)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 2. 三个选项按钮
                        VStack(spacing: 12) {
                            ForEach(data.options) { option in
                                Button(action: {
                                    viewModel.selectOption(option)
                                }) {
                                    Text(option.text)
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.white.opacity(0.6))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(.plain) // 去掉默认点击效果
                            }
                        }
                    }
                }
                .padding(20)
                
                // 弹窗显示时，模糊底层内容
                .blur(radius: viewModel.showResultAlert ? 5 : 0)
                .animation(.easeInOut, value: viewModel.showResultAlert)
                
                // --- 顶层：自定义结果弹窗 ---
                if viewModel.showResultAlert {
                    // 半透明遮罩 (防止误触底层按钮)
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // 可选：点击背景也可以关闭
                            onCloseWindow()
                        }
                    
                    // 弹窗本体
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.green)
                            .padding(.top, 10)
                        
                        Text("事件结果")
                            .font(.headline)
                        
                        Text(viewModel.resultMessage)
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Divider()
                        
                        Button(action: {
                            onCloseWindow()
                        }) {
                            Text("好")
                                .font(.headline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                // .padding(.vertical, 4)
                                .contentShape(Rectangle()) // 扩大点击区域
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .frame(width: 260) // 弹窗宽度
                    .background(.regularMaterial) // 毛玻璃背景
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .transition(.scale.combined(with: .opacity)) // 弹出动画
                }
            }
        }
        // ✨ 4. 获取窗口引用
        .background(WindowAccessor(window: $window))
        // ✨ 5. 监听内容大小变化
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geo.size)
            }
        )
        // ✨ 6. 当大小改变时，调整窗口高度
        .onPreferenceChange(SizePreferenceKey.self) { newSize in
            guard let window = window else { return }
            // 只有当尺寸真的变了才调整，避免死循环
            if window.frame.size != newSize {
                // 保持窗口中心点不变，或者保持左上角不变
                // 这里我们简单地设置 contentSize，macOS 会自动处理坐标
                // 使用动画会让变高变矮的过程更丝滑
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    window.animator().setContentSize(newSize)
                }
            }
        }
        .onAppear {
            // 窗口打开时自动开始生成
            viewModel.generateEvent()
        }
    }
}

// 1. 用于获取 NSWindow 的工具
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// 2. 用于传递尺寸的 PreferenceKey
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
