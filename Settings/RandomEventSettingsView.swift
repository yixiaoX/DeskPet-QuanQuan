//
//  RandomEventSettingsView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/19/26.
//

import SwiftUI

struct RandomEventSettingsView: View {
    // 使用 ViewModel 来管理数据逻辑
    @StateObject private var vm = RandomEventSettingsViewModel()
    
    var body: some View {
        Form {
            // MARK: - 剧本主题设置
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("随机事件的发生场景。AI 将从这里随机抽取一个作为故事背景")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TagFlowLayout(
                        tags: vm.themes,
                        color: .blue
                    ) { tag in
                        vm.removeTheme(tag)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                HStack {
                    Label("剧本主题", systemImage: "theatermasks.fill")
                    Spacer()
                    AddTagButton(title: "添加主题") { newTag in
                        vm.addTheme(newTag)
                    }
                }
            }
            
            // MARK: - 氛围基调设置
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("事件发生时的情感基调。AI 将随机选择其中一个调整故事的走向")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TagFlowLayout(
                        tags: vm.moods,
                        color: .orange
                    ) { tag in
                        vm.removeMood(tag)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                HStack {
                    Label("氛围基调", systemImage: "face.smiling.inverse")
                    Spacer()
                    AddTagButton(title: "添加氛围") { newTag in
                        vm.addMood(newTag)
                    }
                }
            }
            
            // MARK: - 恢复默认
            Section {
                Button("恢复默认配置") {
                    vm.resetDefaults()
                }
                .frame(maxWidth: .infinity, alignment: .center)
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
    RandomEventSettingsView()
}
