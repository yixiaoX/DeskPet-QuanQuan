//
//  GeneralSettingsView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/14/26.
//

import SwiftUI

struct GeneralSettingsView: View {
    // 全局配置
    @AppStorage("alwaysShowInputInBubble") var alwaysShowInputInBubble: Bool = false
    @AppStorage("isInputPermanent") var isInputPermanent: Bool = false
    @AppStorage("reply_limit") private var replyLimit: Int = 50
    @AppStorage("log_context_limit") private var logLimit: Int = 10
    @AppStorage("history_summary_limit") private var summaryLimit: Int = 50
    
    var body: some View {
        Form {
            // MARK: - 💬 气泡设置
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    // 1. 输入框常驻
                    SettingToggleRow(
                        title: "输入框常驻主界面",
                        subtitle: "在宠物头顶始终显示输入框，方便随时聊天",
                        isOn: $isInputPermanent
                    )
                    
                    Divider()
                    
                    // 2. 气泡内始终显示
                    SettingToggleRow(
                        title: "气泡内始终显示输入框",
                        subtitle: "只要气泡出现，就自动展开输入栏",
                        isOn: $alwaysShowInputInBubble
                    )
                    .disabled(isInputPermanent) // 逻辑：如果常驻开启，此项变灰
                    .foregroundColor(isInputPermanent ? .secondary : .primary) // 被常驻覆盖是选项变灰
                }
                .padding(.vertical, 8)
            } header: {
                Label("交互体验", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.headline)
            }
            
            // MARK: - 🧠 AI 聊天参数
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // 1. 回复字数限制
                    CustomStepper(
                        label: "单次回复字数限制",
                        description: "AI 生成的对话、乐评、书评等内容的长度上限。范围为 10 - 500 字",
                        value: $replyLimit,
                        range: 10...500,
                        step: 10,
                        unit: " 字"
                    )
                    
                    Divider()

                    // 2. 上下文条数
                    CustomStepper(
                        label: "对话记忆深度",
                        description: "AI 读取最近对话的条数。数值越大消耗 Token 越多，但连贯性越好。范围为 0 - 50 条",
                        value: $logLimit,
                        range: 0...50,
                        step: 1,
                        unit: " 条"
                    )
                    
                    Divider()
                    
                    // 3. 总结字数限制
                    CustomStepper(
                        label: "长期记忆归档长度",
                        description: "将对话归档为永久记忆时，压缩总结后的文本长度上限。范围为 10 - 500 字",
                        value: $summaryLimit,
                        range: 10...500,
                        step: 10,
                        unit: " 字"
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Label("AI 参数配置", systemImage: "brain.head.profile")
                    .font(.headline)
            }
            
            /*
            // MARK: - 💾 数据存储
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("当前存储路径")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        
                        // 恢复默认按钮
                        if !manager.customPathString.isEmpty {
                            Button("恢复默认位置") {
                                manager.customPathString = ""
                            }
                            .buttonStyle(.link)
                            .controlSize(.small)
                        }
                    }
                    
                    // 路径显示框 (美化版)
                    HStack(spacing: 0) {
                        Image(systemName: "externaldrive.fill")
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                            .padding(.trailing, 4)
                        
                        Text(manager.activeFileURL.path)
                            .font(.system(.caption, design: .monospaced)) // 等宽字体显示路径更专业
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(manager.activeFileURL.path)
                            .padding(.vertical, 6)
                        
                        Spacer()
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // Finder 按钮
                        Button(action: {
                            NSWorkspace.shared.activateFileViewerSelecting([manager.activeFileURL])
                        }) {
                            Image(systemName: "folder")
                                .frame(width: 24)
                        }
                        .buttonStyle(.borderless)
                        .help("在 Finder 中显示")
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // 更改按钮
                        Button("更改...") {
                            selectCustomPath()
                        }
                        .buttonStyle(.borderless)
                        .padding(.horizontal, 10)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .frame(height: 32)
                }
                .padding(.vertical, 8)
            } header: {
                Label("数据存储", systemImage: "internaldrive.fill")
                    .font(.headline)
            }
            */
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Helper Methods
    /*
    private func selectCustomPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "选择保存 History.json 的文件夹"
        
        if panel.runModal() == .OK, let url = panel.url {
            let fullPath = url.appendingPathComponent("History.json")
            manager.customPathString = fullPath.absoluteString
            manager.saveHistory()
        }
    }
    */
}

// MARK: - 🧩 提取出来的子视图组件

/// 统一风格的 Toggle 行
struct SettingToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// 统一风格的数字步进器
struct CustomStepper: View {
    let label: String
    let description: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String
    
    // ✨ 核心修复：创建一个 String 类型的代理绑定
    // 这样可以接管 TextField 的输入逻辑，防止光标乱跳
    private var valueProxy: Binding<String> {
        Binding<String>(
            get: {
                String(value)
            },
            set: { newValue in
                // 1. 过滤掉非数字字符
                let filtered = newValue.filter { "0123456789".contains($0) }
                
                // 2. 尝试转为 Int
                if let intValue = Int(filtered) {
                    // 3. 只有当数值在合理范围内（或者允许暂时超出等待修正）时才更新
                    // 这里我们做个松散限制，防止输入过长（比如 99999）
                    // 具体的 range 限制交给后面的逻辑，或者在输入完成后修正
                    // 为了体验流畅，这里只限制上限不超过 range 上限太多以免溢出
                    if intValue <= 9999 {
                        value = intValue
                    }
                } else if filtered.isEmpty {
                    // 处理删光的情况，设为 range 的下限或 0
                    value = 0
                }
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.body)
                
                Spacer()
                
                // 控件组
                HStack(spacing: 0) {
                    // ➖ 减号
                    StepperButton(icon: "minus") {
                        if value - step >= range.lowerBound {
                            value -= step
                        } else {
                            value = range.lowerBound
                        }
                    }
                    .disabled(value <= range.lowerBound)
                    
                    Divider().frame(height: 16)
                    
                    // 🔢 输入框 (核心修改区)
                    TextField("", text: valueProxy)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        // 使用等宽字体，数字对齐更整齐
                        .font(.system(.body, design: .monospaced))
                        // 修复 1: 加大宽度 (44 -> 55)，给 3 位数留够空间
                        .frame(width: 55)
                        .padding(.vertical, 4)
                        // 提交时（按回车）强制检查范围，修正非法数值
                        .onSubmit {
                            validateRange()
                        }
                        // 失去焦点时也应该检查（但在 SwiftUI macOS 中较难直接捕获，通常 onSubmit 够用）
                    
                    // 单位
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)
                        // 修复 1 补充: 确保单位不会被压缩
                        .layoutPriority(1)
                    
                    Divider().frame(height: 16)
                    
                    // ➕ 加号
                    StepperButton(icon: "plus") {
                        if value + step <= range.upperBound {
                            value += step
                        } else {
                            value = range.upperBound
                        }
                    }
                    .disabled(value >= range.upperBound)
                }
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        // 监听外部变化，确保始终在范围内 (双重保险)
        .onChange(of: value) { _, newValue in
            // 注意：这里不要过于激进地修正，否则打字打到一半会被改掉
            // 比如想输 50，先输了 5，如果下限是 10，这里马上改成 10，用户就疯了。
            // 所以这里只做上限截断，下限检查留给 onSubmit
            if newValue > range.upperBound {
                value = range.upperBound
            }
        }
    }
    
    // 范围验证逻辑
    private func validateRange() {
        if value < range.lowerBound {
            value = range.lowerBound
        } else if value > range.upperBound {
            value = range.upperBound
        }
    }
}

/// 辅助按钮组件
struct StepperButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle()) // 增加点击区域
        }
        .buttonStyle(.borderless)
    }
}
