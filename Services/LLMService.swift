//
//  LLMService.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import Foundation

class LLMService {
    // 单例模式，全局共享
    static let shared = LLMService()
    
    // 私有初始化，强制使用 shared
    private init() {}
    
    // MARK: - 配置读取
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "user_api_key") ?? ""
    }
    
    private var baseURL: String {
        var url = UserDefaults.standard.string(forKey: "user_base_url") ?? "https://api.openai.com/v1"
        // 容错处理：用户如果多复制了 /chat/completions 或结尾斜杠，帮他去掉
        if url.hasSuffix("/chat/completions") {
            url = url.replacingOccurrences(of: "/chat/completions", with: "")
        }
        if url.hasSuffix("/") {
            url.removeLast()
        }
        return url
    }
    
    private var currentModel: String {
        UserDefaults.standard.string(forKey: "user_selected_model") ?? "gpt-3.5-turbo"
    }
    
    // MARK: - 核心功能：发送聊天请求
    
    /// 发送消息给 LLM 并获取回复
    /// - Parameters:
    ///   - messages: 已经封装好的 OpenAIMessage 数组
    ///   - temperature: 随机性 (默认 0.7)
    /// - Returns: AI 的回复内容
    func chatCompletion(messages: [OpenAIMessage], temperature: Double = 0.7) async throws -> String {
        let endpoint = "\(baseURL)/chat/completions"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        // 1. 构造请求体 (严格匹配 LLMModels.swift)
        let requestPayload = OpenAIRequest(
            model: currentModel,
            messages: messages,
            temperature: temperature
        )
        
        // 2. 构造 HTTP 请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 编码
        request.httpBody = try JSONEncoder().encode(requestPayload)
        
        // 3. 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 4. 检查状态码
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            print("❌ LLM API Error: \(httpResponse.statusCode) - \(errorMsg)")
            throw URLError(.badServerResponse)
        }
        
        // 5. 解析响应 (匹配 LLMModels.swift)
        do {
            let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            // 取出第一个选项的 message 内容
            return decodedResponse.choices.first?.message.content ?? ""
        } catch {
            print("❌ JSON Decode Error: \(error)")
            // 打印原始数据方便调试
            if let str = String(data: data, encoding: .utf8) {
                print("Raw Data: \(str)")
            }
            throw error
        }
    }
    
    // MARK: - 辅助功能：获取模型列表
    
    func fetchAvailableModels() async throws -> [String] {
        let endpoint = "\(baseURL)/models"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // 解析 OpenAIModelListResponse
        let decoded = try JSONDecoder().decode(OpenAIModelListResponse.self, from: data)
        
        // 提取 id 并排序
        let modelIDs = decoded.data.map { $0.id }.sorted()
        return modelIDs
    }
}
