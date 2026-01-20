//
//  SharedComponents.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/19/26.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 🧩 组件：JSON 文档包装器
struct JSONFileDocument: FileDocument {
    // 告诉系统这个文档支持 JSON 类型
    static var readableContentTypes: [UTType] { [.json] }
    
    var jsonData: Data
    
    // 初始化方法 1：用于导出（我们把数据塞给它）
    init(jsonData: Data) {
        self.jsonData = jsonData
    }
    
    // 初始化方法 2：用于导入（系统把文件读出来给我们）
    init(configuration: ReadConfiguration) throws {
        self.jsonData = configuration.file.regularFileContents ?? Data()
    }
    
    // 保存方法：把数据写回磁盘
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: jsonData)
    }
}

// MARK: - 🧩 组件：统一风格的文本输入框
struct StyledTextEditor: View {
    let title: String
    @Binding var text: String
    var height: CGFloat = 120
    var helpText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题栏（模仿 Form 的 Label 样式，但为了大输入框独立出来）
            if !title.isEmpty {
                Text(title)
                    .font(.body)
            }
            
            // 输入框本体
            TextEditor(text: $text)
                .font(.system(size: 13))
                .frame(height: height)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor)) // 使用系统标准的输入框背景色
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .help(helpText ?? "")
            
            // 辅助提示文字
            if let help = helpText {
                Text(help)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 🧩 组件：添加按钮 (带弹窗)
struct AddTagButton: View {
    let title: String
    let onAdd: (String) -> Void
    
    @State private var isPresenting = false
    @State private var textInput = ""
    
    var body: some View {
        Button(action: { isPresenting = true }) {
            Image(systemName: "plus")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .popover(isPresented: $isPresenting) {
            VStack(spacing: 12) {
                Text(title).font(.headline)
                TextField("输入新标签", text: $textInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onSubmit {
                        submit()
                    }
                
                HStack {
                    Button("取消") { isPresenting = false }
                    Button("添加") { submit() }.buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }
    
    private func submit() {
        onAdd(textInput)
        textInput = ""
        isPresenting = false
    }
}

// MARK: - 🧩 组件：胶囊标签流式布局 (Flow Layout)
struct TagFlowLayout: View {
    let tags: [String]
    let color: Color
    let onDelete: (String) -> Void
    
    var body: some View {
        // 使用 Layout 协议实现的简易流式布局 (MacOS 13+ 支持 Layout 协议，这里使用万能的 GeometryReader 兼容写法)
        // 为了代码简洁，这里使用一个简单的 WrappingHStack 实现
        WrappingHStack(tags: tags) { tag in
            HStack(spacing: 4) {
                Text(tag)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Button(action: { onDelete(tag) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(color.gradient)
                    .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
            )
        }
    }
}

// 一个简易的自动换行容器
struct WrappingHStack<Content: View>: View {
    let tags: [String]
    let content: (String) -> Content
    
    @State private var totalHeight = CGFloat.zero
    
    var body: some View {
        GeometryReader { geometry in
            var width = CGFloat.zero
            var height = CGFloat.zero
            
            ZStack(alignment: .topLeading) {
                ForEach(tags, id: \.self) { tag in
                    content(tag)
                        .padding([.horizontal, .vertical], 4)
                        .alignmentGuide(.leading, computeValue: { d in
                            if (abs(width - d.width) > geometry.size.width) {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if tag == tags.last! {
                                width = 0 // last item
                            } else {
                                width -= d.width
                            }
                            return result
                        })
                        .alignmentGuide(.top, computeValue: {d in
                            let result = height
                            if tag == tags.last! {
                                height = 0 // last item
                            }
                            return result
                        })
                }
            }
            .background(viewHeightReader($totalHeight))
        }
        .frame(height: totalHeight)
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}
