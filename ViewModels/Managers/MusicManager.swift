//
//  MusicManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/14/26.
//

import Foundation

class MusicManager {
    // 依赖
    private let musicService = MusicService()
    private let chatService = ChatService.shared
    private let historyManager = HistoryManager.shared
    
    // 状态
    var isAutoListening = false
    private var musicTimer: Timer?
    private var lastTrackID: String = ""
    
    // 回调：通知 ViewModel 更新 UI (文字, 是否需要改变动作)
    var onStatusChange: ((String) -> Void)?
    var onReviewGenerated: ((String) -> Void)?
    
    // 切换开关
    func toggleListening() -> Bool {
        isAutoListening.toggle()
        if isAutoListening {
            startLoop()
        } else {
            stopLoop()
        }
        return isAutoListening
    }
    
    // 开始循环
    private func startLoop() {
        checkMusicOnce() // 立即检查一次
        // 每 5 秒检查一次
        musicTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkMusicOnce()
        }
    }
    
    // 停止循环
    private func stopLoop() {
        musicTimer?.invalidate()
        musicTimer = nil
        lastTrackID = "" // 重置记忆
    }
    
    // 检查逻辑
    private func checkMusicOnce() {
        Task {
            // 1. 获取歌曲
            guard let track = musicService.getCurrentTrack() else { return }
            
            // 2. 去重判断
            let currentID = "\(track.title)-\(track.artist)"
            if currentID == lastTrackID { return }
            lastTrackID = currentID
            
            // historyManager.addMessage(role: .user, content: "🎵我正在听「\(track.artist)」的《\(track.title)》") // 存入历史记录
            
            // 3. 发现新歌 -> 通知 UI
            await MainActor.run {
                onStatusChange?("正在听「\(track.artist)」的《\(track.title)》...")
            }
            
            // 4. 请求评价
            do {
                // 调用 ChatService 的 reviewMusic
                let review = try await chatService.reviewMusic(song: track.title, artist: track.artist)
                historyManager.addMessage(role: .ai, content: "🎵 [乐评] \(review)")    // 存入历史记录
                await MainActor.run {
                    onReviewGenerated?(review)
                }
            } catch {
                print("评价失败: \(error)")
            }
        }
    }
}
