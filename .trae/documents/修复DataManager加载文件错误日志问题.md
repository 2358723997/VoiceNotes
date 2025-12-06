# 修复DataManager加载文件错误日志问题

## 1. 问题分析
当应用首次运行或records.json文件不存在时，DataManager的loadRecords()方法会尝试读取该文件并失败，然后打印大量错误信息。这导致控制台被不必要的错误日志填满，影响开发体验。

## 2. 解决方案
修改DataManager.swift文件中的loadRecords()方法，使其在文件不存在时能够优雅地处理，只在文件存在但读取失败时打印错误信息。

## 3. 修改内容

### 3.1 修改loadRecords()方法
- 添加文件存在检查
- 如果文件不存在，直接返回空数组，不打印错误信息
- 只有当文件存在但读取失败时，才打印错误信息

### 3.2 具体修改
```swift
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
```

## 4. 预期效果
- 当records.json文件不存在时，不再打印错误信息
- 只有当文件存在但读取失败时，才打印错误信息
- 减少控制台中的不必要日志，提高开发体验

## 5. 测试计划
修改完成后，运行应用，检查控制台是否不再打印大量文件不存在的错误信息。