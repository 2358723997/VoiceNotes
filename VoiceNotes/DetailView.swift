//
//  DetailView.swift
//  VoiceNotes
//
//  Created by 王积学 on 2025/11/28.
//

import SwiftUI
import Combine
import AVFoundation

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioPlayer = AudioPlayer()
    @ObservedObject var dataManager: DataManager
    
    var record: VoiceRecord
    
    // 显式添加公共初始化器
    public init(dataManager: DataManager, record: VoiceRecord) {
        self.dataManager = dataManager
        self.record = record
    }
    @State private var isEditingTitle = false
    @State private var editedTitle = ""
    @State private var editedText = ""
    @State private var isTranscribing = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showingTranscript = false
    
    // 自动保存文本的定时器
    private var debounceTimer: Timer?
    
    var body: some View {
        NavigationStack {
            if showingTranscript {
                // 转录页面
                ZStack {
                    Color.white
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Text("转录")
                            .font(.headline)
                            .padding(.vertical, 16)
                        
                        ScrollView {
                            Text(editedText.isEmpty ? "暂无转录内容" : editedText)
                                .font(.body)
                                .foregroundColor(.black)
                                .padding(20)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                                .padding(16)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showingTranscript = false
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            } else {
                // 播放页面
                ZStack {
                    Color.white
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        // 标题编辑区域
                        VStack(alignment: .leading, spacing: 8) {
                            if isEditingTitle {
                                TextField("录音标题", text: $editedTitle, onCommit: {
                                    saveTitle()
                                })
                                .font(.body)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                                .onAppear {
                                    editedTitle = record.title
                                }
                            } else {
                                HStack {
                                    Text(record.title)
                                        .font(.body)
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                    Spacer()
                                    Button {
                                        isEditingTitle = true
                                    } label: {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            
                            // 录音信息
                            HStack(spacing: 20) {
                                Text(record.formattedCreatedAt)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(record.formattedDuration)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                if record.transcriptionStatus == .completed {
                                    Text("已转文字")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // 音频播放器
                        VStack(spacing: 12) {
                            // 播放控制和进度条
                            VStack(spacing: 8) {
                                // 进度条和时间
                                VStack(spacing: 4) {
                                    HStack {
                                        Button {  
                                audioPlayer.togglePlayPause()
                            } label: {
                                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 24, height: 24)
                            }
                                        
                                        Slider(value: $audioPlayer.currentTime, in: 0...audioPlayer.duration, onEditingChanged: { isEditing in
                                if !isEditing {
                                    audioPlayer.seek(to: audioPlayer.currentTime)
                                }
                            })
                            .accentColor(.gray)
                                        
                                        Text(audioPlayer.formatTime(audioPlayer.duration))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // 波形图
                            VStack(alignment: .leading) {
                                ForEach(0..<10, id: \.self) { index in
                                    Rectangle()
                                        .fill(Color(.systemGray4))
                                        .frame(height: 4)
                                        .cornerRadius(2)
                                        .padding(.vertical, 2)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        Spacer()
                        
                        // 转录按钮
                        Button {
                            if record.transcriptionStatus == .completed {
                                showingTranscript = true
                            } else {
                                transcribeAudio()
                            }
                        } label: {
                            Text("转录")
                                .foregroundColor(.gray)
                                .font(.body)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                        .disabled(isTranscribing)
                        .padding(.bottom, 40)
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onAppear {
                        editedText = record.text ?? ""
                        // 加载音频文件
                        loadAudio()
                    }
                    .onDisappear {
                        // 保存文本并重置播放器
                        saveText()
                        audioPlayer.reset()
                    }
                }
            }
            
            // 转写过程覆盖层 - 移除额外动画效果
        }

    }
    
    // 加载音频文件
    private func loadAudio() {
        // 根据audioURL的格式决定如何加载
        if let url = URL(string: record.audioURL), url.scheme != nil {
            // 处理网络URL
            do {
                try audioPlayer.loadAudio(url: url)
            } catch {
                print("Failed to load audio from network URL: \(error)")
            }
        } else {
            // 处理本地文件路径
            let fileURL = URL(fileURLWithPath: record.audioURL)
            do {
                try audioPlayer.loadAudio(url: fileURL)
            } catch {
                print("Failed to load audio from file path: \(error)")
            }
        }
    }
    
    // 保存标题
    private func saveTitle() {
        if !editedTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            // 调用API更新标题
            APIService.shared.updateRecordTitle(recordId: record.id, title: editedTitle) { result in
                switch result {
                case .success(let recordItem):
                    // 将API返回的RecordItem转换为VoiceRecord
                    let formatter = ISO8601DateFormatter()
                    let updatedAt = formatter.date(from: recordItem.updated_at) ?? Date()
                    
                    // 更新本地录音记录
                    var updatedRecord = self.record
                    updatedRecord.title = recordItem.title
                    updatedRecord.updatedAt = updatedAt
                    updatedRecord.transcriptionStatus = VoiceRecord.TranscriptionStatus(rawValue: recordItem.transcription_status) ?? .notStarted
                    
                    // 更新本地数据
                    dataManager.updateRecord(updatedRecord)
                case .failure(let error):
                    print("Failed to update title: \(error)")
                }
            }
        }
        isEditingTitle = false
    }
    
    // 保存文本
    private func saveText() {
        dataManager.updateRecordText(recordId: record.id, text: editedText)
    }
    
    // 语音转文字
    private func transcribeAudio() {
        isTranscribing = true
        
        // 提交转写任务
        APIService.shared.submitTranscribeTask(recordId: record.id, audioURL: record.audioURL) { result in
            switch result {
            case .success(let transcribeResponse):
                // 更新本地转写状态
                var updatedRecord = self.record
                updatedRecord.transcriptionStatus = .inProgress
                self.dataManager.updateRecord(updatedRecord)
                
                // 开始轮询转写状态
                self.startPollingTranscriptionStatus(taskId: transcribeResponse.task_id, recordId: self.record.id)
                
            case .failure(let error):
                print("Failed to submit transcribe task: \(error)")
                // 更新转写状态为失败
                self.dataManager.setRecordTranscriptionStatus(recordId: self.record.id, status: .failed)
                self.isTranscribing = false
                // 显示错误提示
                self.errorMessage = "提交转写任务失败"
                self.showErrorAlert = true
            }
        }
    }
    
    // 开始轮询转写状态
    private func startPollingTranscriptionStatus(taskId: String, recordId: String) {
        // 每隔2秒检查一次转写状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkTranscriptionStatus(taskId: taskId, recordId: recordId)
        }
    }
    
    // 检查转写状态
    private func checkTranscriptionStatus(taskId: String, recordId: String) {
        APIService.shared.checkTranscribeStatus(taskId: taskId) { result in
            switch result {
            case .success(let statusResponse):
                // 查找录音记录
                if let index = dataManager.records.firstIndex(where: { $0.id == recordId }) {
                    var updatedRecord = dataManager.records[index]
                    
                    // 更新转写状态
                    if let status = VoiceRecord.TranscriptionStatus(rawValue: statusResponse.status) {
                        updatedRecord.transcriptionStatus = status
                        
                        if status == .completed {
                            updatedRecord.isTranscribed = true
                            updatedRecord.text = statusResponse.text
                            editedText = statusResponse.text ?? ""
                            saveText()
                        }
                        
                        dataManager.updateRecord(updatedRecord)
                    }
                    
                    // 如果转写完成，显示结果
                    if statusResponse.status == "completed" {
                        isTranscribing = false
                        showingTranscript = true
                    } 
                    // 如果转写失败，显示错误
                    else if statusResponse.status == "failed" {
                        isTranscribing = false
                        errorMessage = "转写失败"
                        showErrorAlert = true
                    }
                    // 否则继续轮询
                    else {
                        startPollingTranscriptionStatus(taskId: taskId, recordId: recordId)
                    }
                }
                
            case .failure(let error):
                print("Failed to check transcription status: \(error)")
                
                // 查找录音记录并更新为失败状态
                if let index = dataManager.records.firstIndex(where: { $0.id == recordId }) {
                    var updatedRecord = dataManager.records[index]
                    updatedRecord.transcriptionStatus = .failed
                    dataManager.updateRecord(updatedRecord)
                }
                
                isTranscribing = false
                errorMessage = "检查转写状态失败"
                showErrorAlert = true
            }
        }
    }
    
    // 移除未使用的转写进度视图函数
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockRecord = VoiceRecord(
            title: "测试录音",
            audioURL: "",
            duration: 120.5,
            text: "这是一段测试录音的转写文本。",
            isTranscribed: true
        )
        DetailView(dataManager: DataManager(), record: mockRecord)
    }
}