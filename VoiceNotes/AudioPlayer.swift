//
//  AudioPlayer.swift
//  VoiceNotes
//
//  Created by 王积学 on 2025/11/28.
//

import AVFoundation
import Foundation
import Combine

class AudioPlayer: NSObject, ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    @Published var isPlaying = false
    @Published var currentTime = 0.0
    @Published var duration = 0.0
    @Published var playbackRate: Float = 1.0
    
    let availableRates: [Float] = [1.0, 1.25, 1.5, 2.0]
    
    // 加载音频文件
    func loadAudio(url: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.isMeteringEnabled = true
        audioPlayer?.enableRate = true
        
        duration = audioPlayer?.duration ?? 0.0
        currentTime = 0.0
        
        // 监听播放完成
        audioPlayer?.delegate = self
    }
    
    // 播放音频
    func play() {
        guard let audioPlayer = audioPlayer else { return }
        
        if !isPlaying {
            audioPlayer.rate = playbackRate
            audioPlayer.play()
            startTimer()
            isPlaying = true
        }
    }
    
    // 暂停音频
    func pause() {
        guard let audioPlayer = audioPlayer else { return }
        
        if isPlaying {
            audioPlayer.pause()
            timer?.invalidate()
            isPlaying = false
        }
    }
    
    // 切换播放/暂停状态
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    // 设置播放进度
    func seek(to time: Double) {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.currentTime = time
        currentTime = time
    }
    
    // 设置播放速度
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if let audioPlayer = audioPlayer, isPlaying {
            audioPlayer.rate = rate
        }
    }
    
    // 开始计时更新进度
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let audioPlayer = self.audioPlayer else { return }
            self.currentTime = audioPlayer.currentTime
        }
    }
    
    // 重置播放器状态
    func reset() {
        timer?.invalidate()
        audioPlayer?.stop()
        isPlaying = false
        currentTime = 0.0
        duration = 0.0
        playbackRate = 1.0
        audioPlayer = nil
    }
    
    // 格式化时间为 mm:ss 格式
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = duration
        timer?.invalidate()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio player decode error: \(error?.localizedDescription ?? "Unknown error")")
        isPlaying = false
        timer?.invalidate()
    }
}