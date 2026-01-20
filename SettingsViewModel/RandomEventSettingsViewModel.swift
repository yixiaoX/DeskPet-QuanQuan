//
//  RandomEventSettingsViewModel.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/19/26.
//

import SwiftUI
import Combine

class RandomEventSettingsViewModel: ObservableObject {
    @Published var themes: [String] = []
    @Published var moods: [String] = []
    
    private let chatService = ChatService.shared
    
    init() {
        loadData()
    }
    
    func loadData() {
        self.themes = chatService.eventThemes
        self.moods = chatService.eventMoods
    }
    
    func addTheme(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !themes.contains(trimmed) else { return }
        themes.append(trimmed)
        save()
    }
    
    func removeTheme(_ tag: String) {
        themes.removeAll { $0 == tag }
        save()
    }
    
    func addMood(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !moods.contains(trimmed) else { return }
        moods.append(trimmed)
        save()
    }
    
    func removeMood(_ tag: String) {
        moods.removeAll { $0 == tag }
        save()
    }
    
    func resetDefaults() {
        UserDefaults.standard.removeObject(forKey: "random_event_themes")
        UserDefaults.standard.removeObject(forKey: "random_event_moods")
        loadData() // 重新加载默认值
    }
    
    private func save() {
        chatService.eventThemes = themes
        chatService.eventMoods = moods
    }
}
