//
//  DataManager.swift
//  VoiceNotes
//
//  Created by 王积学 on 2025/11/28.
//

import Foundation
import Combine

class DataManager: ObservableObject {
    @Published var records: [VoiceRecord] = []
    
    private let recordsFileName = "records.json"
    private let fileManager = FileManager.default
    
    // 初始化时加载数据
    init() {
        loadRecords()
    }
    
    // 获取文档目录URL
    private var documentsURL: URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // 获取记录文件URL
    private var recordsFileURL: URL {
        return documentsURL.appendingPathComponent(recordsFileName)
    }
    
    // 加载录音记录
    func loadRecords() {
        // 检查文件是否存在
        if !fileManager.fileExists(atPath: recordsFileURL.path) {
            // 文件不存在，直接返回空数组
            records = []
            return
        }
        
        do {
            let data = try Data(contentsOf: recordsFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([VoiceRecord].self, from: data)
            // 按创建时间倒序排列
            records.sort { $0.createdAt > $1.createdAt }
        } catch {
            print("Failed to load records: \(error)")
            records = []
        }
    }
    
    // 保存录音记录
    func saveRecords() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(records)
            try data.write(to: recordsFileURL)
        } catch {
            print("Failed to save records: \(error)")
        }
    }
    
    // 添加新的录音记录
    func addRecord(_ record: VoiceRecord) {
        records.insert(record, at: 0) // 插入到列表开头
        saveRecords()
    }
    
    // 更新录音记录
    func updateRecord(_ updatedRecord: VoiceRecord) {
        if let index = records.firstIndex(where: { $0.id == updatedRecord.id }) {
            records[index] = updatedRecord
            saveRecords()
        }
    }
    
    // 删除录音记录
    func deleteRecord(_ record: VoiceRecord) {
        // 注意：在新架构下，音频文件存储在后端，这里只删除本地记录
        // 实际项目中应调用后端API删除服务器上的音频文件
        print("提示：需要调用后端API删除ID为 \(record.id) 的音频文件（URL: \(record.audioURL)）")

        // 从列表中删除记录
        records.removeAll { $0.id == record.id }
        saveRecords()
    }
    
    // 搜索录音记录
    func searchRecords(query: String) -> [VoiceRecord] {
        if query.isEmpty {
            return records
        }
        
        let lowercaseQuery = query.lowercased()
        return records.filter { record in
            record.title.lowercased().contains(lowercaseQuery) ||
            record.text?.lowercased().contains(lowercaseQuery) ?? false
        }
    }
    
    // 更新录音文本
    func updateRecordText(recordId: String, text: String) {
        if let index = records.firstIndex(where: { $0.id == recordId }) {
            var updatedRecord = records[index]
            updatedRecord.text = text
            updatedRecord.isTranscribed = true
            updatedRecord.updateTimestamp()
            records[index] = updatedRecord
            saveRecords()
        }
    }
    
    // 设置转写状态（用于API回调）
    func setRecordTranscriptionStatus(recordId: String, status: VoiceRecord.TranscriptionStatus) {
        if let index = records.firstIndex(where: { $0.id == recordId }) {
            var updatedRecord = records[index]
            updatedRecord.transcriptionStatus = status
            if status == .completed {
                updatedRecord.isTranscribed = true
            }
            updatedRecord.updateTimestamp()
            records[index] = updatedRecord
            saveRecords()
        }
    }
    
    // 从后端同步数据（模拟方法，实际应调用API）
    func syncWithBackend(completion: @escaping (Error?) -> Void) {
        // 模拟网络请求延迟
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // 在实际项目中，这里应调用后端API获取最新数据
            print("提示：需要实现从后端同步录音数据的API调用")
            completion(nil)
        }
    }
    
    // 更新录音标题
    func updateRecordTitle(recordId: String, title: String) {
        if let index = records.firstIndex(where: { $0.id == recordId }) {
            var updatedRecord = records[index]
            updatedRecord.title = title
            updatedRecord.updateTimestamp()
            records[index] = updatedRecord
            saveRecords()
        }
    }
}