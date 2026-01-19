//
//  StatsManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/15/26.
//

import Foundation
import Combine

@MainActor
class StatsManager: ObservableObject {
    static let shared = StatsManager()
    
    // 持久化存储 Key
    private let kCoins = "user_coins"
    private let kMood = "pet_mood"
    private let kLastCheckInDate = "last_check_in_date"
    
    @Published var coins: Int {
        didSet { UserDefaults.standard.set(coins, forKey: kCoins) }
    }
    
    @Published var mood: Int {
        didSet { UserDefaults.standard.set(mood, forKey: kMood) }
    }
    
    @Published var isCheckedInToday: Bool = false
    
    private init() {
        // 读取保存的数据，如果没有则使用默认值
        self.coins = UserDefaults.standard.object(forKey: kCoins) as? Int ?? 50 //初始金币 50
        self.mood = UserDefaults.standard.object(forKey: kMood) as? Int ?? 80 // 初始心情 80
        
        checkSignInStatus()
    }
    
    // MARK: - 签到逻辑
    private func checkSignInStatus() {
        guard let lastDate = UserDefaults.standard.object(forKey: kLastCheckInDate) as? Date else {
            isCheckedInToday = false
            return
        }
        isCheckedInToday = Calendar.current.isDateInToday(lastDate)
    }
    
    /// 执行签到，返回获得的金币数量
    func performCheckIn() -> Int {
        if isCheckedInToday { return 0 }
        
        let reward = Int.random(in: 20...50)
        self.coins += reward
        
        // 更新日期
        UserDefaults.standard.set(Date(), forKey: kLastCheckInDate)
        self.isCheckedInToday = true
        
        return reward
    }
    
    // MARK: - 交易与属性逻辑
    
    /// 尝试消费金币
    func trySpendCoins(amount: Int) -> Bool {
        if coins >= amount {
            coins -= amount
            return true
        }
        return false
    }
    
    /// 增加心情值 (上限 100)
    func increaseMood(amount: Int) {
        mood = min(mood + amount, 100)
    }
    
    /// (可选) 减少心情值，用于随时间衰减
    func decreaseMood(amount: Int) {
        mood = max(mood - amount, 0)
    }
}
