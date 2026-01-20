//
//  FocusSettingsView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/18/26.
//

import SwiftUI

struct FocusSettingsView: View {
    @AppStorage("focus_default_duration") private var defaultDuration: Double = 25
    
    @StateObject private var vm = FocusSettingsViewModel()
    
    var body: some View {
        Form {
            // MARK: - 时长设置
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("时长")
                        Spacer()
                        Text("\(Int(defaultDuration)) 分钟")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .monospacedDigit()
                    }
                    
                    HStack{
                        Text("这会作为启动弹窗中的默认数值")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $defaultDuration, in: 5...120, step: 5) {
                            EmptyView()
                        } minimumValueLabel: {
                            Text("5m").font(.caption)
                        } maximumValueLabel: {
                            Text("120m").font(.caption)
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Label("专注时长", systemImage: "clock")
                    .font(.headline)
            }
            
            // MARK: - 黑名单设置
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("当检测到前台应用名称包含以下关键词时，宠物会进行警告。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if vm.tags.isEmpty {
                        Text("暂无黑名单")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.5))
                            .italic()
                            .padding(.vertical, 8)
                    } else {
                        // 复用你的 TagFlowLayout 组件
                        TagFlowLayout(
                            tags: vm.tags,
                            color: .red
                        ) { tag in
                            vm.removeTag(tag)
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                HStack {
                    Label("应用黑名单", systemImage: "hand.raised.slash.fill")
                        .font(.headline)
                    Spacer()
                    // 复用你的 AddTagButton 组件
                    AddTagButton(title: "添加违禁应用") { newTag in
                        vm.addTag(newTag)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
#Preview {
    FocusSettingsView()
}
