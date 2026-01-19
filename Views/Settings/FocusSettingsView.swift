//
//  FocusSettingsView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/18/26.
//

import SwiftUI

struct FocusSettingsView: View {
    @AppStorage("focus_default_duration") private var defaultDuration: Double = 25
    @AppStorage("focus_blacklist") private var blackListText: String = ""
    
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
                // ✨ 使用统一风格的编辑器
                StyledTextEditor(
                    title: "", // Section header 已经有了，这里留空
                    text: $blackListText,
                    height: 140,
                    helpText: "当检测到前台应用名称包含以上关键词（逗号分隔）时，宠物会进行警告"
                )
            } header: {
                Label("应用黑名单", systemImage: "hand.raised.slash.fill")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }
}
#Preview {
    FocusSettingsView()
}
