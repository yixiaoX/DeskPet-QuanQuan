//
//  DeskPet_QuanQuanApp.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import SwiftUI

@main
struct TianchengPetApp: App {
    // 连接刚才写的 AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 这里的 Settings 仅仅是为了让菜单栏里有“偏好设置”选项
        // 实际窗口逻辑已经交给 AppDelegate 处理了
        Settings {
            SettingsView()
                //.frame(width: 650, height: 500)
        }
    }
}
