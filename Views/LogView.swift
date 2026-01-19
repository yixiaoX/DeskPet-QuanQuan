//
//  LogView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/16/26.
//

import SwiftUI
import Combine

// MARK: - ViewModel (新增)
@MainActor
class LogViewModel: ObservableObject {
    @Published var recentLogs: [ChatMessage] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 订阅数据库变化
        DatabaseService.shared.observeAllMessages()
            .map { (temp, _) -> [ChatMessage] in
                // temp 在 DatabaseService 中已经是按时间倒序排列 (最新的在最前)
                // 我们取最新的 10 条
                let latest = temp.prefix(10)
                
                // 为了符合人类阅读习惯（从上到下时间递增），我们需要反转数组
                return Array(latest.reversed())
            }
            .receive(on: DispatchQueue.main) // 确保在主线程更新 UI
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] logs in
                self?.recentLogs = logs
            })
            .store(in: &cancellables)
    }
}

// MARK: - View
struct LogView: View {
    @StateObject private var vm = LogViewModel()
    
    var body: some View {
        // 使用统一窗口容器
        GlassyWindowContainer(width: 380, height: 400, onClose: {
            LogWindowManager.shared.close()
        }){
            // --- 主内容区域 ---
            VStack(spacing: 0) {
                // 1. 顶部栏 (标题 + 设置按钮)
                HStack {
                    // 占位，给关闭按钮留出空间
                    Color.clear.frame(width: 26, height: 24)
                    
                    Text("最近对话记录")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary.opacity(0.8))
                    
                    Spacer()
                    
                    // 右上角：历史管理入口
                    Button(action: {
                        HistoryWindowManager.shared.show()
                        LogWindowManager.shared.close()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "gearshape.fill") // 换成实心齿轮，语义更强
                                .font(.system(size: 12))
                            Text("管理")
                                .font(.system(size: 12, weight: .medium))
                        }
                        // ✨ 视觉样式：内边距撑开体积
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        // ✨ 背景：使用半透明的主色 (自适应深色/浅色模式)
                        .background(Color.primary.opacity(0.1))
                        // ✨ 形状：圆角矩形 (cornerRadius: 6 看起来比较方正硬朗，8 比较圆润)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        // ✨ 描边：加一圈淡淡的边框增加精致感
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain) // 必须用 plain，否则会有系统默认的按钮底色
                    .help("打开详细历史记录管理")
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 10)
                
                Divider().background(Color.gray.opacity(0.2))
                
                // 2. 消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(vm.recentLogs) { msg in
                                LogRow(msg: msg)
                                    .id(msg.id) // 绑定 ID 用于滚动定位
                            }
                        }
                        .padding(16)
                    }
                    .onAppear {
                        // 打开时自动滚动到底部
                        scrollToBottom(proxy: proxy)
                    }
                    // 当新消息进来时也滚动
                    .onChange(of: vm.recentLogs.count) {
                        scrollToBottom(proxy: proxy)
                    }
                    // 额外监听最后一条消息 ID 的变化 (应对数量不变但内容变的情况)
                    .onChange(of: vm.recentLogs.last?.id) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
        }
    }
    
    // 页面滚动逻辑
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastID = vm.recentLogs.last?.id {
            // 稍微延迟一点点，确保布局加载完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - 单条日志行视图
struct LogRow: View {
    let msg: ChatMessage
    
    // 时间格式化
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 图标
            if msg.role == .user {
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                    .frame(width: 20, height: 20)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            } else if msg.role == .ai {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
                    .frame(width: 20, height: 20)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Circle())
            } else {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                    .frame(width: 20, height: 20)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // 内容
                Text(msg.content)
                    .font(.system(size: 13))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineLimit(nil) // 允许换行
                    .fixedSize(horizontal: false, vertical: true)
                
                // 时间
                Text("\(msg.timestamp, formatter: Self.formatter)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding(.vertical, 2)
    }
}
