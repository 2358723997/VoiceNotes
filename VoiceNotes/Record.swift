//
//  Record.swift
//  VoiceNotes
//
//  Created by 王积学 on 2025/11/28.
//

import Foundation

struct VoiceRecord: Identifiable, Codable {
    var id: String
    var title: String
    let audioURL: String // 修改为音频URL，指向后端存储的音频文件
    var text: String?
    let duration: Double
    var createdAt: Date
    var updatedAt: Date
    var isTranscribed: Bool
    var transcriptionStatus: TranscriptionStatus = .notStarted // 转写状态
    
    // 转写状态枚举
    enum TranscriptionStatus: String, Codable {
        case notStarted = "not_started"
        case inProgress = "in_progress"
        case transcribing = "transcribing" // 兼容代码中使用的transcribing状态
        case completed = "completed"
        case failed = "failed"
    }
    
    init(title: String, audioURL: String, duration: Double, text: String? = nil, isTranscribed: Bool = false) {
        self.id = UUID().uuidString
        self.title = title
        self.audioURL = audioURL
        self.text = text
        self.duration = duration
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isTranscribed = isTranscribed
        self.transcriptionStatus = isTranscribed ? .completed : .notStarted
    }
    
    // 添加一个从旧格式初始化的便利构造器，用于兼容现有数据
    init(title: String, audioPath: String, duration: Double, text: String? = nil, isTranscribed: Bool = false) {
        // 将本地路径作为临时URL使用
        self.init(title: title, audioURL: audioPath, duration: duration, text: text, isTranscribed: isTranscribed)
    }
    
    // 更新最后修改时间
    mutating func updateTimestamp() {
        self.updatedAt = Date()
    }
    
    // 格式化时长为 mm:ss 格式
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // 格式化创建时间
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}