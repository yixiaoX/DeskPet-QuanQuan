//
//  PetSettingsView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import SwiftUI

struct PetSettingsView: View {
    @AppStorage("pet_name") private var petName = "泉泉"
    @AppStorage("pet_gender") private var petGender = ""
    @AppStorage("pet_call_user") private var petCallUser = "主人"
    @AppStorage("pet_persona") private var petPersona = "傲娇、可爱"
    
    var body: some View {
        Form {
            // MARK: - 基本信息
            Section {
                TextField("名字", text: $petName)
                TextField("性别", text: $petGender)
            } header: {
                Label("基本信息", systemImage: "info.circle")
                    .font(.headline)
            }
            
            // MARK: - 性格设定
            Section {
                TextField("对我的称呼", text: $petCallUser)
                    .help("例如：主人、哥哥、姐姐、老板")
                
                // ✨ 使用统一风格的编辑器
                StyledTextEditor(
                    title: "详细人设",
                    text: $petPersona,
                    height: 120,
                    helpText: "描述它的性格特点、喜好、说话风格等。提示：修改后语气会立刻改变哦！"
                )
                
            } header: {
                Label("性格设定", systemImage: "face.smiling")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }
}
