//
//  SettingsBackupManager.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/19/26.
//

import Foundation

import Foundation
import SwiftUI

class SettingsBackupManager {
    static let shared = SettingsBackupManager()
    
    // 📝 1.在此处维护所有需要备份的 Key
    // 这样做的好处是安全，不会把意外的系统数据或敏感数据（如 API Key）导出去
    private let keysToBackup: [String] = [
        // --- 基础设置 ---
        "alwaysShowInputInBubble",
        "isInputPermanent",
        
        // --- AI 参数 ---
        "reply_limit",
        "log_context_limit",
        "history_summary_limit",
        
        // --- 角色设定 (ChatService) ---
        "pet_name",
        "pet_gender",
        "pet_call_user",
        "pet_persona",
        "pet_mood",
        
        // --- 用户设定 ---
        "user_name",
        "user_gender",
        "user_relation",
        "user_background",
        "user_coins",
        
        // --- 随机事件 ---
        "random_event_themes",
        "random_event_moods",
        
        // --- 专注模式 ---
        "focus_default_duration",
        "focus_blacklist"
    ]
    
    // MARK: - 📤 导出
    func exportSettings() -> URL? {
        var exportDict: [String: Any] = [:]
        
        for key in keysToBackup {
            if let value = UserDefaults.standard.object(forKey: key) {
                exportDict[key] = value
            }
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
            
            // 创建临时文件
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "DeskPet_Settings_Backup_\(Int(Date().timeIntervalSince1970)).json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("导出设置失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 📥 导入
    func importSettings(from url: URL) -> Bool {
        // 安全访问权限
        let gotAccess = url.startAccessingSecurityScopedResource()
        defer { if gotAccess { url.stopAccessingSecurityScopedResource() } }
        
        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return false
            }
            
            // 遍历并恢复数据
            for (key, value) in json {
                // 安全检查：只恢复我们在白名单里的 key
                if keysToBackup.contains(key) {
                    UserDefaults.standard.set(value, forKey: key)
                }
            }
            
            // 强制同步 (虽然新版 macOS 会自动同步，但为了保险)
            UserDefaults.standard.synchronize()
            return true
        } catch {
            print("导入设置失败: \(error)")
            return false
        }
    }
}
