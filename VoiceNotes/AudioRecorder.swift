//
//  AudioRecorder.swift
//  VoiceNotes
//
//  Created by 王积学 on 2025/11/28.
//

import AVFoundation
import Foundation
import Combine

class AudioRecorder: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingDuration = 0.0
    @Published var recordingURL: URL?
    
    // 请求麦克风权限
    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // 开始录音
    func startRecording() throws {
        // 设置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true)
        
        // 创建录音文件URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let audioURL = documentsPath.appendingPathComponent(fileName)
        recordingURL = audioURL
        
        // 录音设置
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // 初始化录音器
        audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        
        // 开始计时
        startTimer()
        
        isRecording = true
        isPaused = false
    }
    
    // 暂停录音
    func pauseRecording() {
        if isRecording && !isPaused {
            audioRecorder?.pause()
            timer?.invalidate()
            isPaused = true
        }
    }
    
    // 继续录音
    func resumeRecording() {
        if isRecording && isPaused {
            audioRecorder?.record()
            startTimer()
            isPaused = false
        }
    }
    
    // 停止录音
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        timer?.invalidate()
        isRecording = false
        isPaused = false
        
        // 重置音频会话
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        return recordingURL
    }
    
    // 开始计时
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1
        }
    }
    
    // 重置录音器状态
    func reset() {
        timer?.invalidate()
        recordingDuration = 0.0
        recordingURL = nil
        isRecording = false
        isPaused = false
    }
    
    // 获取当前录音的平均功率（用于波形显示）
    var averagePower: Float {
        audioRecorder?.updateMeters()
        return audioRecorder?.averagePower(forChannel: 0) ?? 0
    }
}