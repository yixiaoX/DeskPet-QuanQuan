//
//  GameCenterView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/17/26.
//

import SwiftUI

// 定义游戏类型 (以后加游戏就在这里加 case)
enum GameType: String, CaseIterable {
    case rps = "猜拳"
    case dice = "掷骰子"
    // case lottery = "刮刮乐" // 示例：以后可以直接加
}

struct GameCenterView: View {
    @ObservedObject var petViewModel = PetViewModel()
    
    @State private var selectedGame: GameType = .rps
    
    var body: some View {
        // ✨ 使用统一容器，指定大小和关闭动作
        GlassyWindowContainer(width: 440, height: 400, onClose: {
            GameWindowManager.shared.close()
        }) {
            // 这里只需要写内部布局
            VStack(spacing: 20) {
                // TabBar
                CustomGameTabBar(selectedTab: $selectedGame)
                    .padding(.top, 20) // 避开左上角关闭按钮
                
                // 游戏内容
                ZStack {
                    switch selectedGame {
                    case .rps:
                        RockPaperScissorsGame(petViewModel: petViewModel)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    case .dice:
                        DiceGame(petViewModel: petViewModel)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.2), value: selectedGame)
            }
        }
    }
}

// MARK: - 自定义胶囊 TabBar
struct CustomGameTabBar: View {
    @Binding var selectedTab: GameType
    @Namespace private var animationNamespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(GameType.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            ZStack {
                                if selectedTab == tab {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.1))
                                        .matchedGeometryEffect(id: "TabBackground", in: animationNamespace)
                                }
                            }
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.primary.opacity(0.05))
        .clipShape(Capsule())
        .frame(width: 200) // 控制 TabBar 总宽度
    }
}
