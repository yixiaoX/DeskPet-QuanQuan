//
//  AdvancedSettingsView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/19/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct AdvancedSettingsView: View {
    // 设置导入/导出状态
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportDocument: JSONFileDocument?
    @State private var showResultAlert = false
    @State private var resultMessage = ""
    
    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("导出配置")
                            .font(.body)
                        Text("将你的所有个性化设置（人设、黑名单、随机事件等）保存为文件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("导出...") {
                        // 1. 准备导出数据
                        if let url = SettingsBackupManager.shared.exportSettings(),
                           let data = try? Data(contentsOf: url) {
                            self.exportDocument = JSONFileDocument(jsonData: data)
                            self.showExporter = true
                        } else {
                            self.resultMessage = "导出失败：无法生成数据"
                            self.showResultAlert = true
                        }
                    }
                }
                .padding(.vertical, 4)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("导入配置")
                            .font(.body)
                        Text("从备份文件恢复设置（建议导入后重启应用）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("导入...") {
                        self.showImporter = true
                    }
                }
                .padding(.vertical, 4)
                
            } header: {
                Label("配置备份", systemImage: "gearshape.2.fill")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
        .fixedSize(horizontal: false, vertical: true)
        // 弹窗修饰符
        // 1. 导出保存弹窗
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "DeskPet_Settings_Backup"
        ) { result in
            if case .success = result {
                resultMessage = "配置导出成功！"
                showResultAlert = true
            }
        }
        
        // 2. 导入选择弹窗
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                if SettingsBackupManager.shared.importSettings(from: url) {
                    resultMessage = "配置导入成功！\n请重启应用以确保所有改动生效。"
                } else {
                    resultMessage = "导入失败：文件格式错误或内容损坏"
                }
                showResultAlert = true
            }
        }
        
        // 3. 结果提示
        .alert("系统提示", isPresented: $showResultAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(resultMessage)
        }
    }
}
