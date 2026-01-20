//
//  HistorySettingsView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/14/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct HistorySettingsView: View {
    @StateObject var vm = HistorySettingsViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // --- 顶部说明 ---
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 34))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("对话历史管理")
                        .font(.headline)
                    Text("右键单击对话条目进行编辑。选中（多个）左侧条目点击中间按钮，AI 会自动总结后归档入右侧永久记忆")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            // .padding(.top)
            
            // --- 核心双栏区域 ---
            GeometryReader { geo in
                HStack(spacing: 16) {
                    // 左侧：对话历史
                    HistoryListColumn(
                        title: "对话历史",
                        count: vm.temporaryMessages.count,
                        selection: Binding(
                            get: { vm.selectedTempIDs },
                            set: { newValue in
                                // 强制在主线程下一个循环更新，避开视图渲染冲突
                                DispatchQueue.main.async {
                                    vm.selectedTempIDs = newValue
                                }
                            }
                        ),
                        messages: vm.temporaryMessages,
                        onDelete: vm.deleteSelectedTemp,
                        onDoubleTap: { msg in
                            vm.startEditing(msg, isPermanent: false)
                        }
                    )
                    
                    // 中间：操作按钮 (垂直居中)
                    VStack(spacing: 12) {
                        Spacer()
                        
                        // 向右按钮
                        if vm.isSummarizing {
                            // 正在总结时显示转圈
                            ProgressView()
                                // .controlSize(.small)
                                .scaleEffect(0.8)
                        } else {
                            // 正常按钮
                            Button(action: {
                                // 触发异步任务
                                Task {
                                    await vm.summarizeAndMoveToPermanent()
                                }
                            }) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .buttonStyle(.bordered)
                            // .controlSize(.small)
                            .disabled(vm.selectedTempIDs.isEmpty)
                            .help("AI 总结并归档到永久记忆")
                        }
                        
                        Spacer()
                    }
                    .frame(width: 20)
                    
                    // 右侧：永久记录
                    HistoryListColumn(
                        title: "永久记忆",
                        count: vm.permanentMessages.count,
                        selection: Binding( // 强制在主线程下一个循环更新，避开视图渲染冲突
                            get: { vm.selectedPermIDs },
                            set: { newValue in
                                DispatchQueue.main.async {
                                    vm.selectedPermIDs = newValue
                                }
                            }
                        ),
                        messages: vm.permanentMessages,
                        onDelete: vm.deleteSelectedPerm,
                        onDoubleTap: { msg in
                            vm.startEditing(msg, isPermanent: true)
                        }
                    )
                }
            }
            .padding(.horizontal)
            
            // 底部全局操作栏
            HStack(spacing: 12) {
                // 危险操作 1
                Button(action: { vm.showClearTempAlert = true }) {
                    Label("清空历史", systemImage: "trash")
                }
                .foregroundColor(.red) // 警示色 (macOS 上可能不明显，但语义正确)
                
                Spacer()
                // 导入导出组
                Group {
                    Button(action: { vm.showFileImporter = true }) {
                        Label("导入", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(action: { vm.prepareExport() }) {
                        Label("导出", systemImage: "square.and.arrow.up")
                    }
                }
                
                Spacer()
                
                // 危险操作 2
                Button(action: { vm.showClearPermAlert = true }) {
                    Label("清空记忆", systemImage: "trash.fill")
                }
                .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(minHeight: 550, alignment: .top)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
        .fixedSize(horizontal: false, vertical: false)
        
        // ✨✨✨ 核心：添加编辑弹窗
        .sheet(item: $vm.editingMessage) { msg in
            EditMessageSheet(message: msg) { newContent, newDate in
                vm.saveEdits(newContent: newContent, newDate: newDate)
            }
        }
        
        // MARK: - ✨ 各种弹窗修饰符
        
        // 1. 导入文件选择器
        .fileImporter(
            isPresented: $vm.showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            // result 是 Result<[URL], Error>，我们取第一个
            if case .success(let urls) = result, let url = urls.first {
                vm.handleImport(result: .success(url))
            }
        }
        
        // 2. 导出文件保存器
        .fileExporter(
            isPresented: $vm.showFileExporter,
            document: vm.exportDocument,
            contentType: .json,
            defaultFilename: "DeskPet_History_Backup"
        ) { _ in }
        
        // 3. 清空历史确认
        .alert("确定清空所有对话历史吗？", isPresented: $vm.showClearTempAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                vm.clearAllTemporary()
            }
        } message: {
            Text("此操作不可恢复，左侧列表将被清空")
        }
        
        // 4. 清空记忆确认
        .alert("确定清空所有永久记忆吗？", isPresented: $vm.showClearPermAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                vm.clearAllPermanent()
            }
        } message: {
            Text("慎重！这是AI的核心记忆，清空后它将忘记之前总结的所有重要信息。此操作不可恢复")
        }
        
        // 5. 错误提示
        .alert("错误", isPresented: $vm.showErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(vm.errorMessage ?? "未知错误")
        }
    }
}

// MARK: - ✨ 封装的原生风格列表组件
struct HistoryListColumn: View {
    let title: String
    let count: Int
    @Binding var selection: Set<UUID>
    let messages: [ChatMessage]
    let onDelete: () -> Void
    let onDoubleTap: (ChatMessage) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 列表头部
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text("\(count) 条")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor)) // 浅灰色背景
            
            Divider()
            
            // 2. 列表内容 (白色背景)
            List(selection: $selection) {
                ForEach(messages) { msg in
                    HistoryRow(msg: msg)
                        // ✨✨✨ 添加交互：右键菜单编辑
                        .contextMenu {
                            Button("编辑内容") {
                                onDoubleTap(msg)
                            }
                            /*
                            Button("删除") {
                                // 这里要调用删除比较麻烦，暂时先只做编辑
                                // 如果想做，可以把 selection 设置为 [msg.id] 然后调 onDelete
                            }
                            */
                        }
                }
            }
            .listStyle(.plain) // 去掉默认背景，由我们自己控制
            .background(Color(nsColor: .textBackgroundColor)) // 纯白或纯黑
            
            Divider()
            
            // 3. 底部工具栏 (Xcode 风格)
            HStack {
                Button(action: onDelete) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless) // 无边框按钮，融入工具栏
                .controlSize(.small)
                .disabled(selection.isEmpty)
                .padding(.leading, 8)
                
                Spacer()
            }
            .frame(height: 28)
            .background(Color(nsColor: .controlBackgroundColor)) // 与头部呼应
        }
        // ✨ 核心：给整个栏加上原生边框
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 行视图美化
struct HistoryRow: View {
    let msg: ChatMessage
    
    @AppStorage("pet_name") private var petName = "宠物"
    @AppStorage("user_name") private var userName = "我"
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 第一行：角色图标 + 时间 (元数据行)
            HStack {
                // 角色
                if msg.role == .user {
                    Label(userName, systemImage: "person.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                } else if msg.role == .ai {
                    Label(petName, systemImage: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Label("系统", systemImage: "gearshape.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                // 时间
                Text("\(msg.timestamp, formatter: Self.dateFormatter)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            // 第二行：正文内容 (尽可能多显示)
            Text(msg.content)
                .font(.system(size: 11)) // ✨ 字体更小
                .foregroundColor(.primary.opacity(0.9))
                .lineLimit(4) // ✨ 最多显示 3 行，不再是 1 行
                .truncationMode(.tail)
                .lineSpacing(1) // 稍微增加行间距提升可读性
                .frame(maxWidth: .infinity, alignment: .leading) // 确保左对齐
        }
        .padding(.vertical, 6) // 上下留一点呼吸空间
    }
}

// MARK: - 编辑文本框
struct EditMessageSheet: View {
    let message: ChatMessage
    let onSave: (String, Date) -> Void
    
    @AppStorage("pet_name") private var petName = "宠物"
    @AppStorage("user_name") private var userName = "我"
    
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isContentFocused: Bool
    @State private var textContent: String
    @State private var timestamp: Date
    
    // 初始化状态
    init(message: ChatMessage, onSave: @escaping (String, Date) -> Void) {
        self.message = message
        self.onSave = onSave
        
        // 使用下划线 _textContent 来访问 State 的底层存储并初始化
        _textContent = State(initialValue: message.content)
        _timestamp = State(initialValue: message.timestamp)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("编辑记忆内容")
                .font(.headline)
            
            // 顶部元数据区域 (角色 + 时间)
            HStack {
                //角色
                Text("角色:")
                    .foregroundColor(.secondary)
                if message.role == .user {
                    Label(userName, systemImage: "person.circle.fill").foregroundColor(.blue)
                } else if message.role == .ai {
                    Label(petName, systemImage: "sparkles").foregroundColor(.green)
                } else {
                    Label("系统", systemImage: "gearshape.fill").foregroundColor(.orange)
                }
                Spacer()
                
                // 时间选择器
                DatePicker("时间", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden() // 隐藏标签，只显示时间
                    .controlSize(.small)
            }
            .font(.caption)
            
            // 多行文本编辑器
            TextEditor(text: $textContent)
                .font(.body)
                .frame(minWidth: 300, minHeight: 150) // 给足够大的空间
                .padding(4)
                .background(Color(nsColor: .textBackgroundColor))
                .border(Color.gray.opacity(0.2), width: 1)
                .focused($isContentFocused)           // 视图聚焦
            
            // 底部按钮
            HStack {
                Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("保存") {
                    onSave(textContent, timestamp)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [.command]) // Cmd + Enter 保存
            }
        }
        .padding()
        .frame(width: 400) // 弹窗宽度
        .onAppear {
            //稍微延迟一点点以确保视图完全加载后再聚焦，体验更稳
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isContentFocused = true
            }
        }
    }
}
