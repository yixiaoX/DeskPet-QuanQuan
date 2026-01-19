//
//  FoodStoreViewModel.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/15/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
struct FoodItem: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String // 这里存图片的文件名 (例如 "baozi")
    let price: Int
    let color: Color // 背景装饰色
}

@MainActor
class FoodStoreViewModel: ObservableObject {
    static let shared = FoodStoreViewModel()
    
    @ObservedObject var statsManager = StatsManager.shared
    
    @Published var showToast: String? = nil
    
    // ✨✨✨ 根据 Assets.xcassets 中添加的图片文件名更新商品列表
    let foods: [FoodItem] = [
        // FoodItem(name: "包子", imageName: "baozi", price: 0, color: .yellow), // 测试
        FoodItem(name: "包子", imageName: "baozi", price: 10, color: .yellow),
        FoodItem(name: "馄饨", imageName: "huntun", price: 15, color: .mint),
        FoodItem(name: "牛肉面", imageName: "beef_noodle", price: 25, color: .orange),
        FoodItem(name: "清汤面", imageName: "noodle", price: 12, color: .brown),
        FoodItem(name: "米线", imageName: "mixian", price: 18, color: .red),
        
        FoodItem(name: "柠檬水", imageName: "lemonwater", price: 5, color: .blue),
        FoodItem(name: "奶茶", imageName: "milktea", price: 7, color: .brown),
        FoodItem(name: "橙汁", imageName: "orangejuice", price: 8, color: .orange),
        FoodItem(name: "帕菲杯", imageName: "parfait", price: 15, color: .pink),
        FoodItem(name: "西瓜", imageName: "watermelon", price: 10, color: .green)
    ]
    
    // 购买逻辑
    func buyFood(_ item: FoodItem) {
        if statsManager.trySpendCoins(amount: item.price) {
            statsManager.increaseMood(amount: 10)
            showToast = "投喂成功！心情 +10"
        } else {
            showToast = "金币不足哦！"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showToast = nil
        }
    }
    
    // 签到逻辑
    func checkIn() {
        if !statsManager.isCheckedInToday {
            let reward = statsManager.performCheckIn()
            showToast = "签到成功！金币 +\(reward)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.showToast = nil }
        }
    }
}
