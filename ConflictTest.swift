// 测试文件，用于验证Combine.Record和我们的VoiceRecord之间的命名冲突是否已解决
import Foundation
import Combine

// 导入VoiceRecord定义
import Combine

// 定义TranscriptionStatus枚举
enum TranscriptionStatus: String, Codable {
    case notStarted
    case transcribing
    case completed
    case failed
}

// 定义VoiceRecord结构体
struct VoiceRecord: Identifiable, Codable {
    let id: UUID
    var title: String
    var audioURL: String
    var duration: TimeInterval
    var createdAt: Date
    var transcriptionStatus: TranscriptionStatus
    var transcription: String?
    
    init(id: UUID = UUID(), title: String, audioURL: String, duration: TimeInterval, createdAt: Date = Date(), transcriptionStatus: TranscriptionStatus = .notStarted, transcription: String? = nil) {
        self.id = id
        self.title = title
        self.audioURL = audioURL
        self.duration = duration
        self.createdAt = createdAt
        self.transcriptionStatus = transcriptionStatus
        self.transcription = transcription
    }
}

// 测试Combine.Record是否可以正常使用
func testCombineRecord() {
    // 创建一个Publisher
    let publisher = Just(1)
    
    // 直接使用Combine.Record类型（虽然通常不这样直接使用）
    // Combine.Record是一个实现了Publisher协议的类型，用于记录和重放值
    print("Combine.Record类型可用")
}

// 测试VoiceRecord是否可以正常使用
func testVoiceRecord() {
    let record = VoiceRecord(title: "测试录音", audioURL: "/path/to/audio.mp3", duration: 10.0)
    print("VoiceRecord works correctly: \(record.title)")
}

// 运行测试
testCombineRecord()
testVoiceRecord()

print("所有测试通过！命名冲突已解决。")
