//
//  SettingsView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            // --- Tab 1: 通用 ---
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
            
            // --- Tab 2: API 连接 ---
            ConnectionSettingsView()
                .tabItem {
                    Label("网络连接", systemImage: "network")
                }
            
            // --- Tab 3: 宠物设定 ---
            PetSettingsView()
                .tabItem {
                    Label("角色设定", systemImage: "pawprint.fill")
                }
            
            // --- Tab 4: 用户设定 ---
            UserSettingsView()
                .tabItem {
                    Label("我的档案", systemImage: "person.fill")
                }
            
            // --- Tab 5: 专注模式
            FocusSettingsView()
                .tabItem {
                    Label("专注模式", systemImage: "timer")
                }
            
            // --- Tab 6: 历史管理 ---
            HistorySettingsView()
                .tabItem {
                    Label("历史管理", systemImage: "document")
                }
            
            /*
            // --- 关于 (可选) ---
            VStack(spacing: 20) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 64, height: 64)
                Text("Pet Izumi")
                    .font(.title)
                Text("版本 Alpha v0.0.1")
                    .foregroundColor(.secondary)
            }
            .tabItem {
                Label("关于", systemImage: "info.circle")
            }
            */
        }
        // .padding()
        .frame(width: 600, alignment: .top)
    }
}

// 统一风格的文本输入框
struct StyledTextEditor: View {
    let title: String
    @Binding var text: String
    var height: CGFloat = 120
    var helpText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题栏（模仿 Form 的 Label 样式，但为了大输入框独立出来）
            if !title.isEmpty {
                Text(title)
                    .font(.body)
            }
            
            // 输入框本体
            TextEditor(text: $text)
                .font(.system(size: 13))
                .frame(height: height)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor)) // 使用系统标准的输入框背景色
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .help(helpText ?? "")
            
            // 辅助提示文字
            if let help = helpText {
                Text(help)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
}

