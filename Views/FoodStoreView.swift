//
//  FoodStoreView.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/15/26.
//

import SwiftUI

struct FoodStoreView: View {
    @ObservedObject var petViewModel = PetViewModel()
    
    @StateObject var foodViewModel = FoodStoreViewModel.shared
    
    // 调整一下列宽，让图片显示更舒服
    let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 130), spacing: 16)
    ]
    
    var body: some View {
        GlassyWindowContainer(width: 540, height: 500, onClose: {
            if let window = NSApp.windows.first(where: { $0 is FoodWindow }) { window.close() }
        }) { // 使用 ZStack 以便放置关闭按钮
            
            // --- 主内容区域 ---
            VStack(spacing: 0) {
                // 1. 顶部状态栏
                HStack {
                    // 最左侧是关闭按钮
                    Spacer()
                    Spacer()
                    
                    // 心情
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill").foregroundColor(.pink)
                        ProgressView(value: Double(foodViewModel.statsManager.mood), total: 100)
                            .frame(width: 80)
                            .tint(.pink)
                        Text("\(foodViewModel.statsManager.mood)").font(.caption)
                    }
                    
                    Spacer()
                    
                    // 金币
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill").foregroundColor(.yellow)
                        Text("\(foodViewModel.statsManager.coins)").monospacedDigit()
                    }
                    .padding(6)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(8)
                    
                    // 签到
                    Button(action: foodViewModel.checkIn) {
                        Text(foodViewModel.statsManager.isCheckedInToday ? "已签到" : "签到")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .disabled(foodViewModel.statsManager.isCheckedInToday)
                }
                .padding(.horizontal)
                .padding(.top, 20) // 顶部留白多一点，避免太挤
                .padding(.bottom, 10)
                
                Divider()
                    .background(Color.gray.opacity(0.3)) // 分割线淡一点
                
                ZStack(alignment: .bottom) {
                    // 2. 商品列表
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(foodViewModel.foods) { food in
                                FoodItemCard(food: food) {
                                    foodViewModel.buyFood(food)
                                    Task {
                                        try await petViewModel.feed(food: food.name)
                                    }
                                }
                            }
                        }
                        .padding(20) // 内容内边距
                        .padding(.bottom, 60)
                    }
                    
                    // 3. Toast 提示
                    if let msg = foodViewModel.showToast {
                        Text(msg)
                            .font(.footnote)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Material.thick) // Toast 用深一点的毛玻璃
                            .clipShape(Capsule())
                            .cornerRadius(20)
                            .shadow(radius: 2)
                            .padding(.bottom, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(), value: foodViewModel.showToast)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: foodViewModel.showToast)
            }
        }
    }
}

// MARK: - 食物卡片组件
struct FoodItemCard: View {
    let food: FoodItem
    let onBuy: () -> Void
    
    // 鼠标悬停状态
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 10) {
            // 图片背景区
            ZStack {
                // 淡色背景圆圈
                Circle()
                    .fill(food.color.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                // 食物图片
                Image(food.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 55, height: 55) // 控制图片大小
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2) // 给食物加一点阴影更有立体感
                    // 鼠标悬停时，让食物稍微浮起来一点点，增加灵动感
                    .offset(y: isHovering ? -3 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
            }
            
            // 信息区域
            VStack(spacing: 6) {
                Text(food.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // 购买按钮
                Button(action: onBuy) {
                    HStack(spacing: 2) {
                        Image(systemName: "cart.fill")
                            .font(.caption2)
                        Text("\(food.price)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15)) // 浅蓝色背景
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        
        // ✨✨✨ 核心修改：双重半透明效果 ✨✨✨
        
        // 1. 背景改用 thinMaterial (比窗口的 regularMaterial 更薄/亮)
        // 配合 opacity 让它在深色模式下也不会太死板
        .background(.thinMaterial)
        
        // 2. 也可以叠加一层淡淡的白色，增加“发光”感 (可选)
        .background(Color.white.opacity(0.1))
        
        .cornerRadius(16)
        
        // 3. 边缘发光描边 (Glassmorphism 经典的高光边缘)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
        )
        
        // 4. 阴影不要太重，保持轻盈
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        
        // 交互逻辑
        .scaleEffect(isHovering ? 1.02 : 1.0) // 整体轻微放大
        .animation(.spring(response: 0.3), value: isHovering)
        
        .onHover { hovering in
            isHovering = hovering
            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}
