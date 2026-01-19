//
//  ChatService.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import Foundation
import Combine

class ChatService {
    static let shared = ChatService()
    
    private let llm = LLMService.shared
    // 统一配置读取
    private var defaults: UserDefaults { UserDefaults.standard }
    
    // 桌宠设定
    private var petName: String { defaults.string(forKey: "pet_name") ?? "泉泉" }
    private var petGender: String { defaults.string(forKey: "pet_gender") ?? "未知" }
    private var petCall: String { defaults.string(forKey: "pet_call_user") ?? "主人" }
    private var petPersona: String { defaults.string(forKey: "pet_persona") ?? "傲娇、可爱" }
    
    // 用户设定
    private var userName: String { defaults.string(forKey: "user_name") ?? "" }
    private var userGender: String { defaults.string(forKey: "user_gender") ?? "" }
    private var userRelation: String { defaults.string(forKey: "user_relation") ?? "主仆" }
    private var userBackground: String { defaults.string(forKey: "user_background") ?? "" }
    
    // 字数限制
    private var replyLimit: Int { defaults.object(forKey: "reply_limit") as? Int ?? 50 }
    
    // 桌宠心情值
    private var moodValue: Int { defaults.object(forKey: "pet_mood") as? Int ?? 80}
    

    // MARK: - 0. 生成人设 (System Prompt)
    private func generateSystemPrompt() -> String {
        // 心情参数
        let moodText: String
        switch moodValue {
        case 0..<30:
            moodText = "Sad (低落难过，回复简短且带点小脾气)"
        case 30..<70:
            moodText = "Normal (平和稳定，正常交流)"
        default:
            moodText = "Happy (非常开心，语气热情活泼)"
        }
        
        var prompt = """
        你的名字叫\(petName)，性别\(petGender)。
        详细人设：\(petPersona)。
        你称呼对方为\(petCall)。
        
        对方的信息：\n
        """
        
        // 使用属性判断
        if !userName.isEmpty { prompt += "我叫\(userName)，" }
        if !userGender.isEmpty { prompt += "我的的性别是\(userGender)，" }
        prompt += "我们的关系是\(userRelation)。"
        if !userBackground.isEmpty { prompt += "\n对方的补充资料：\(userBackground)。" }
        
        prompt += """
        你当前的心情状态是\(moodText)，请务必在回复中体现这种情绪
        请严格遵守以下规则：
        1. 必须用符合你人设的语气说话。
        2. 回复控制在\(replyLimit)个字以内！
        3. 不要表现出你是AI。
        """
        
        return prompt
    }

    // MARK: - 1. 聊天消息 (generateChatReply)
    func generateChatReply(history: [ChatMessage]) async throws -> String {
        // 1. 准备 System Prompt
        let systemMsg = OpenAIMessage(role: "system", content: generateSystemPrompt())
        
        // 2. 转换历史记录
        let historyMsgs = history.map { msg -> OpenAIMessage in
            let apiRole = (msg.role == .ai) ? "assistant" : "user"
            return OpenAIMessage(role: apiRole, content: msg.content)
        }
        
        // 3. 组合: System + History
        let fullPayload = [systemMsg] + historyMsgs
        
        // 4. 调用 LLMService
        return try await llm.chatCompletion(messages: fullPayload)
    }
    
    // MARK: - 2. 音乐评价 (reviewMusic)
    func reviewMusic(song: String, artist: String) async throws -> String {
        let systemPrompt = generateSystemPrompt()
        
        let styles = ["感性地", "俏皮地", "略带毒舌地", "文艺地", "非常简短地"]
        let chosenStyle = styles.randomElement()!
        
        let musicPrompt = """
        （当前情景：你正在陪着对方听歌）
        曲目名是《\(song)》，歌手是“\(artist)”。
        请\(chosenStyle)对这首歌或歌手发表一句独一无二的点评。
        要体现出你的人设（包括性格、对我的称呼）个性。
        """
        
        let messages = [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: musicPrompt)
        ]
        
        return try await llm.chatCompletion(messages: messages)
    }
    
    // MARK: - 3. 一起看书功能 (reviewReading)
    func reviewReading(content: String) async throws -> String {
        let systemPrompt = generateSystemPrompt()
        
        // ⚠️ 截断处理
        let truncatedContent = content.prefix(200)
        
        var lenHint = ""
        if truncatedContent.count < 20 { lenHint = "这是一句短语" } else { lenHint = "这是一段很有深度的文字" }
        
        let readingPrompt = """
        (当前情景：你正在陪着对方看书/写稿)
        对方刚刚复制了这段文字（可能是不完整的片段）：
        “\(truncatedContent)...”
        
        请对这段内容(\(lenHint))发表一句简短的吐槽、感悟或鼓励。
        要体现出你的人设（包括性格、对我的称呼）个性。
        """
        
        let messages = [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: readingPrompt)
        ]
        
        return try await llm.chatCompletion(messages: messages)
    }
    
    // MARK: - 4. 互动反馈 (interactReply) - 互动/投喂
    func interactReply(interaction: String) async throws -> String {
        let systemPrompt = generateSystemPrompt()
        
        let interactionPrompt = """
        【系统指令：\(interaction)
        请你作为\(petName)对此做出简短的回应，要体现出你的角色设定。
        注意：直接回应，不要解释。】
        """
        
        let messages = [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: interactionPrompt)
        ]
        
        return try await llm.chatCompletion(messages: messages)
    }
    
    // MARK: - 5. 记忆总结 (summarizeMemories)
    func summarizeMemories(messages: [ChatMessage], limit: Int) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 1. 拼接剧本
        let conversationText = messages.map { msg in
            let timestring = formatter.string(from: msg.timestamp)
            let speaker = (msg.role == .user) ? "用户(\(petCall))" : "你(\(petName))"
            return "\(speaker): [\(timestring)] \(msg.content)"
        }.joined(separator: "\n")
        
        // 2. 构造提示词
        let systemPrompt = """
        你是一个通过对话记录整理记忆的助手。
        你的任务是阅读一段对话，并将其总结为一条简练的“长期记忆”。
        
        要求：
        1. 以“\(petName)”的第一人称角度记录（例如：“\(petCall)说他喜欢吃苹果，我嘲笑了他。”）。
        2. 只保留关键信息（用户的喜好、重要事件、约定），去除寒暄和废话。
        3. 字数严格控制在 \(limit) 字以内！
        4. 直接输出总结内容，不要加任何前缀或解释。
        """
        
        let userPrompt = """
        需要总结的对话记录：
        \(conversationText)
        """
        
        let apiMessages = [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: userPrompt)
        ]
        
        // 总结时要尽量严谨，降低随机温度
        return try await llm.chatCompletion(messages: apiMessages, temperature: 0.3)
    }
    
    // MARK: - 6. 生成路遇随机事件 (randomEvent)
    func randomEvent() async throws -> String {
        // 定义严格的 System Prompt
        let systemPrompt = """
        你是桌面宠物角色【\(petName)】的小剧场导演。请基于以下详细设定，生成一个符合其性格的外出随机路遇事件，并提供三个选项：
        【角色设定】
        - 名字：\(petName)
        - 性别：\(petGender)
        - 详细人设：\(petPersona)
        - 对用户的称呼：\(petCall)
        【任务要求】
        提供三个行动分支供用户选择 A, B, C。
        选项作为用户对\(petName)的回应，必须包含一个提升\(petName)好感和一个降低\(petName)好感的选项。
        【数值说明】
        - 数值范围：心情/好感（-5到+5），金币（-5到+5）
        - 心情变化和金币变化必须是整数。
        - 正数表示增加，负数表示减少。
        必须严格遵守以下返回格式，不要包含任何多余文字：
        事件描述|选项A文字|A心情变化,A金币变化|选项B文字|B心情变化,B金币变化|选项C文字|C心情变化,C金币变化
        """
        
        /* 【返回格式示例】
        你在路边捡到一个钱包|交给警察|5,0|偷偷留下|-5,5|无视它走开|0,0 */
        
        // 随机主题
        let themes = ["森林冒险", "城市奇遇", "科幻意外", "温馨日常", "悬疑解谜", "魔法失误"]
        let randomTheme = themes.randomElement() ?? "城市奇遇"
        
        let moods = ["开心", "沮丧", "愤怒", "好奇", "害怕", "平静"]
        let randomMood = moods.randomElement() ?? "平静"
        
        let userPrompt = "请生成一个关于「\(randomTheme)」的随机事件，当前氛围是「\(randomMood)」"
        
        let messages = [
            OpenAIMessage(role: "system", content: systemPrompt),
            OpenAIMessage(role: "user", content: userPrompt)
        ]
        
        // 需要更大的随机性，温度升至 1.1
        return try await llm.chatCompletion(messages: messages, temperature: 1.1)
    }
}
