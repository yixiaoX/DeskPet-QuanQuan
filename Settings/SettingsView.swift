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
            
            // --- Tab 5: 随机事件配置 ---
            RandomEventSettingsView()
                .tabItem {
                    Label("随机事件", systemImage: "theatermask.and.paintbrush")
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
            
            // --- Tab 7: 高级设置 ---
            AdvancedSettingsView()
                .tabItem {
                    Label("高级", systemImage: "gearshape.2")
                }
            
            /*
            // --- 关于 (可选) ---
            VStack(spacing: 20) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 64, height: 64)
                Text("Izumi")
                    .font(.title)
                Text("版本 Alpha v0.1.1")
                    .foregroundColor(.secondary)
            }
            .tabItem {
                Label("关于", systemImage: "info.circle")
            }
            */
        }
        // .padding()
        .frame(width: 560, alignment: .top)
    }
}

#Preview {
    SettingsView()
}

