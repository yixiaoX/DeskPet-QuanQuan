//
//  UserSettingsView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import SwiftUI

struct UserSettingsView: View {
    @AppStorage("user_name") private var userName = ""
    @AppStorage("user_gender") private var userGender = ""
    @AppStorage("user_relation") private var userRelation = ""
    @AppStorage("user_background") private var userBackground = ""
    
    var body: some View {
        Form {
            // MARK: - 基础信息
            Section {
                TextField("我的名字", text: $userName)
                TextField("我的性别", text: $userGender)
            } header: {
                Label("我是谁", systemImage: "person.circle")
                    .font(.headline)
            }
            
            // MARK: - 羁绊设定
            Section {
                TextField("我们的关系", text: $userRelation)
                    .help("例如：朋友、父女、恋人、搭档")
                
                // ✨ 使用统一风格的编辑器
                StyledTextEditor(
                    title: "我的背景",
                    text: $userBackground,
                    height: 120,
                    helpText: "告诉它你平时在做什么，它会更懂你的梗"
                )
                
            } header: {
                Label("羁绊设定", systemImage: "heart.text.square")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }
}
