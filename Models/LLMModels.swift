//
//  LLMModels.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import Foundation

// 1. 发送给 API 的数据格式
struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

// 2. API 返回的数据格式
struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: OpenAIMessage
}

// 3. 解析 /v1/models 的结构
struct OpenAIModelListResponse: Codable {
    let data: [OpenAIModel]
}

struct OpenAIModel: Codable, Identifiable, Hashable {
    let id: String
    // 有些接口返回里有 owner 等字段，我们暂时只需要 id
}
