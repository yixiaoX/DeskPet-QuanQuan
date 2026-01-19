//
//  ConnectionSettingsView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import SwiftUI

struct ConnectionSettingsView: View {
    // --- API 连接设置 ---
    @AppStorage("user_api_key") private var apiKey = ""
    @AppStorage("user_base_url") private var baseURL = "https://api.openai.com/v1"
    @AppStorage("user_selected_model") private var selectedModel = "gpt-3.5-turbo"
    
    // --- 本地状态 ---
    @State private var availableModels: [String] = ["gpt-3.5-turbo", "gpt-4", "deepseek-chat", "deepseek-reasoner"]
    @State private var isLoadingModels = false
    @State private var statusMessage = ""
    
    var body: some View {
        Form {
            Section {
                TextField("API URL", text: $baseURL)
                SecureField("API Key", text: $apiKey)
            } header: {
                Label("API 配置", systemImage: "server.rack")
                    .font(.headline)
            }
            
            Section {
                HStack {
                    Picker("当前模型", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    Button(action: refreshModels) {
                        if isLoadingModels {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(apiKey.isEmpty || isLoadingModels)
                    .help("从服务器拉取最新模型列表")
                }
            } header: {
                Label("模型选择", systemImage: "cpu")
                    .font(.headline)
            }
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            // 自动拉取逻辑
            if availableModels.count <= 2 && !apiKey.isEmpty {
                refreshModels()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    // --- 拉取模型逻辑 ---
    private func refreshModels() {
        guard !apiKey.isEmpty else { return }
        isLoadingModels = true
        statusMessage = "正在拉取..."
        
        Task {
            do {
                // ✨✨✨ 修改点：使用 LLMService.shared 单例
                let models = try await LLMService.shared.fetchAvailableModels()
                
                await MainActor.run {
                    self.availableModels = models
                    // 智能修正：如果当前选的模型不在列表里，默认选第一个
                    if !models.contains(selectedModel), let first = models.first {
                        selectedModel = first
                    }
                    self.statusMessage = "成功获取 \(models.count) 个模型"
                    self.isLoadingModels = false
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "拉取失败: \(error.localizedDescription)"
                    self.isLoadingModels = false
                }
            }
        }
    }
}
