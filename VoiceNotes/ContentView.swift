//
//  ContentView.swift
//  VoiceNotes
//
//  Created by 王积学 on 2025/11/28.
//

import SwiftUI
import Combine


// DetailView已在单独的文件中定义

struct ContentView: View {
    // 已直接定义Record结构体，避免与Combine.Record冲突
    @StateObject private var dataManager = DataManager()
    @State private var searchQuery = ""
    @State private var isRecordingViewPresented = false
    
    // 过滤后的录音记录
    var filteredRecords: [VoiceRecord] {
        if searchQuery.isEmpty {
            return dataManager.records
        } else {
            return dataManager.records.filter { $0.title.lowercased().contains(searchQuery.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("搜索", text: $searchQuery)
                        .autocorrectionDisabled()
                        // SwiftUI 版本兼容性处理
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(16)
                
                // 录音列表
                List {
                    if filteredRecords.isEmpty {
                        // 空状态提示
                        VStack(spacing: 16) {
                            Image(systemName: "mic.slash.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                            Text(searchQuery.isEmpty ? "暂无录音记录" : "未找到匹配的录音")
                                .font(.body)
                                .foregroundColor(.gray)
                            Text(searchQuery.isEmpty ? "点击下方按钮开始录音" : "尝试调整搜索关键词")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        // 录音记录列表
                ForEach(filteredRecords) { record in
                            NavigationLink(destination: DetailView(dataManager: dataManager, record: record)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(record.title)
                                                .font(.body)
                                                .foregroundColor(.black)
                                                .lineLimit(1)
                                            // 根据转写状态显示不同的标签
                                            switch record.transcriptionStatus {
                                            case .completed:
                                                Text("已转文字")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.gray.opacity(0.2))
                                                    .cornerRadius(4)
                                            case .transcribing:
                                                Text("转写中...")
                                                    .font(.caption2)
                                                    .foregroundColor(.blue)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(4)
                                            case .failed:
                                                Text("转写失败")
                                                    .font(.caption2)
                                                    .foregroundColor(.red)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.red.opacity(0.1))
                                                    .cornerRadius(4)
                                            default:
                                                // 未转写状态不显示标签
                                                EmptyView()
                                            }
                                        }
                                        HStack(spacing: 6) {
                                            Text(record.formattedCreatedAt)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("•")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text(record.formattedDuration)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                // 删除按钮
                                Button(role: .destructive) {
                                    dataManager.deleteRecord(record)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.white)
            }
            .navigationTitle("语音笔记")
            .toolbar {
                // 导航栏右侧可以添加设置等按钮
            }
            .sheet(isPresented: $isRecordingViewPresented) {
                // 录音页面
                RecordingView(dataManager: dataManager)
            }
            // 悬浮按钮 - 调整缩进格式
            .overlay(alignment: .bottomTrailing) {
                Button(action: { 
                    isRecordingViewPresented = true 
                }) { 
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 60, height: 60)
                        Image(systemName: "plus")
                            .foregroundColor(.red)
                            .font(.title)
                    }
                }
                .padding(.bottom, 40)
                .padding(.trailing, 16)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
