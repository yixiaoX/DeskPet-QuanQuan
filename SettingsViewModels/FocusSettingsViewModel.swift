//
//  FocusSettingsViewModel.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/19/26.
//

import SwiftUI
import Combine

class FocusSettingsViewModel: ObservableObject {
    @Published var tags: [String] = []
    
    // 存取数组
    private let storageKey = "focus_blacklist"
    
    init() {
        loadData()
    }
    
    // 1. 读取：直接读数组
    func loadData() {
        // 直接请求 stringArray，如果没有则给空数组
        self.tags = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
    }
    
    // 2. 添加：简化逻辑
    func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 依然保留简单的去重逻辑
        if !tags.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            tags.append(trimmed)
            save()
        }
    }
    
    // 3. 删除
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        save()
    }
    
    // 4. 保存：直接存数组
    private func save() {
        UserDefaults.standard.set(tags, forKey: storageKey)
        // 立即同步，防止意外丢失
        UserDefaults.standard.synchronize()
    }
}
