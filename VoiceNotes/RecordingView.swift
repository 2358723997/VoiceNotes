//
//  RecordingView.swift
//  VoiceNotes
//
//  Created by 王积学 on 2025/11/28.
//

import SwiftUI
import AVFoundation

struct RecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioRecorder = AudioRecorder()
    @ObservedObject var dataManager: DataManager
    
    @State private var showPermissionAlert = false
    @State private var isProcessing = false
    
    // 录音时长格式化
    var formattedDuration: String {
        let minutes = Int(audioRecorder.recordingDuration) / 60
        let seconds = Int(audioRecorder.recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            // 背景色
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 录音按钮
                Button {  
                    toggleRecording()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(width: 160, height: 160)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 160, height: 160)
                        if audioRecorder.isRecording && !audioRecorder.isPaused {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 60, height: 60)
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 60, height: 60)
                        }
                    }
                }
                
                // 录音时长
                Text(formattedDuration)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.black)
                
                // 控制按钮
                if audioRecorder.isRecording {
                    HStack(spacing: 60) {
                        // 暂停/继续按钮
                        Button {  
                            toggleRecording()
                        } label: {
                            Image(systemName: audioRecorder.isPaused ? "play.fill" : "pause.fill")
                                .foregroundColor(.black)
                                .font(.system(size: 24))
                                .frame(width: 40, height: 40)
                        }
                        
                        // 停止录音按钮
                        Button {  
                            stopRecording()
                        } label: {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.black)
                                .font(.system(size: 24))
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("录音")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {  
                        cancelRecording()
                    }
                    .disabled(isProcessing)
                    .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 右侧留白
                    Text("")
                        .frame(width: 40)
                }
            }
            .alert("需要麦克风权限", isPresented: $showPermissionAlert) {
                Button("去设置") {
                    // 打开设置
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("请在设备设置中允许访问麦克风以录制音频")
            }
            .overlay {
                if isProcessing {
                    // 处理中遮罩
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("处理中...")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .medium))
                        }
                    }
                }
            }
        }
    }
    
    // 开始录音
    private func startRecording() {
        Task {
            let hasPermission = await audioRecorder.requestPermission()
            if hasPermission {
                do {
                    try audioRecorder.startRecording()
                } catch {
                    print("Failed to start recording: \(error)")
                }
            } else {
                showPermissionAlert = true
            }
        }
    }
    
    // 暂停/继续录音
    private func toggleRecording() {
        if audioRecorder.isRecording {
            if audioRecorder.isPaused {
                continueRecording()
            } else {
                pauseRecording()
            }
        } else {
            startRecording()
        }
    }
    
    // 继续录音
    private func continueRecording() {
        audioRecorder.resumeRecording()
    }
    
    // 暂停录音
    private func pauseRecording() {
        audioRecorder.pauseRecording()
    }
    
    // 取消录音
    private func cancelRecording() {
        if audioRecorder.isRecording {
            _ = audioRecorder.stopRecording() // 忽略返回值
        }
        dismiss()
    }
    
    // 停止录音
    private func stopRecording() {
        // 不需要设置isRecording，audioRecorder.stopRecording()会自动处理
        isProcessing = true
        
        if let audioURL = audioRecorder.stopRecording() {
            // 1. 上传音频文件
            APIService.shared.uploadAudio(fileURL: audioURL) { result in
                switch result {
                case .success(let uploadResponse):
                    // 2. 创建录音记录
                    let title = self.generateDefaultTitle()
                    let audioURL = uploadResponse.audio_url
                    let duration = self.audioRecorder.recordingDuration
                    
                    APIService.shared.createRecord(title: title, audioURL: audioURL, duration: duration) { result in
                        switch result {
                        case .success(let recordItem):
                            // 将API返回的RecordItem转换为VoiceRecord
                            let formatter = ISO8601DateFormatter()
                            let createdAt = formatter.date(from: recordItem.created_at) ?? Date()
                            let updatedAt = formatter.date(from: recordItem.updated_at) ?? Date()
                            
                            let voiceRecord = VoiceRecord(
                                title: recordItem.title,
                                audioURL: recordItem.audio_url,
                                duration: recordItem.duration,
                                text: recordItem.text,
                                isTranscribed: recordItem.is_transcribed
                            )
                            
                            // 设置id、时间和转写状态
                            var updatedVoiceRecord = voiceRecord
                            updatedVoiceRecord.id = recordItem.id
                            updatedVoiceRecord.createdAt = createdAt
                            updatedVoiceRecord.updatedAt = updatedAt
                            updatedVoiceRecord.transcriptionStatus = VoiceRecord.TranscriptionStatus(rawValue: recordItem.transcription_status) ?? .notStarted
                            
                            // 3. 添加到数据管理器
                            self.dataManager.addRecord(updatedVoiceRecord)
                            
                            // 4. 提交转写任务
                            APIService.shared.submitTranscribeTask(recordId: recordItem.id, audioURL: audioURL) { result in
                                switch result {
                                case .success(let transcribeResponse):
                                    // 5. 更新录音转写状态
                                    var updatedRecord = updatedVoiceRecord
                                    updatedRecord.transcriptionStatus = .inProgress
                                    self.dataManager.updateRecord(updatedRecord)
                                    
                                    // 6. 轮询转写状态
                                    self.startPollingTranscriptionStatus(taskId: transcribeResponse.task_id, recordId: recordItem.id)
                                    
                                case .failure(let error):
                                    print("Failed to submit transcribe task: \(error)")
                                    // 更新录音转写状态为失败
                                    var updatedRecord = updatedVoiceRecord
                                    updatedRecord.transcriptionStatus = .failed
                                    self.dataManager.updateRecord(updatedRecord)
                                }
                            }
                            
                        case .failure(let error):
                            print("Failed to create record: \(error)")
                        }
                    }
                
                case .failure(let error):
                    print("Failed to upload audio: \(error)")
                }
                
                // 关闭页面
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.dismiss()
                }
            }
        } else {
            // 没有录音文件，直接关闭页面
            DispatchQueue.main.async {
                self.isProcessing = false
                self.dismiss()
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
                        }
                        
                        dataManager.updateRecord(updatedRecord)
                    }
                    
                    // 如果转写未完成，继续轮询
                    if statusResponse.status != "completed" && statusResponse.status != "failed" {
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
            }
        }
    }
    
    // 生成默认标题
    private func generateDefaultTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "录音 · \(formatter.string(from: Date()))"
    }
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView(dataManager: DataManager())
    }
}