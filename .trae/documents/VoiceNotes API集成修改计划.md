# VoiceNotes API集成修改计划

## 1. 概述
根据提供的API文档，需要修改APIService.swift文件，使其符合新的API规范，包括统一的响应格式、正确的API端点和请求/响应模型。

## 2. 修改内容

### 2.1 基础URL修改
- 将baseURL从`https://api.voicenotes.example.com`更改为`http://localhost:8000/api`

### 2.2 统一API响应模型
- 添加通用API响应模型，支持文档中定义的统一响应格式
- 包含success、data、message和error_code字段

### 2.3 录音管理API实现
- 获取录音列表：GET /records
- 获取录音详情：GET /records/{record_id}
- 创建录音记录：POST /records
- 更新录音标题：PUT /records/{record_id}/title
- 删除录音：DELETE /records/{record_id}

### 2.4 音频管理API实现
- 上传音频文件：POST /audio/upload
- 下载音频文件：GET /audio/{file_name}

### 2.5 语音转文字API实现
- 提交转写任务：POST /transcribe/
- 查询转写状态：GET /transcribe/{task_id}
- 获取转写结果：GET /transcribe/record/{record_id}

### 2.6 模型更新
- 更新TranscriptionResponse模型，支持新的API响应格式
- 添加任务状态模型，支持转写任务的查询

## 3. 实现步骤

1. 修改baseURL常量
2. 添加通用API响应模型
3. 添加录音相关的请求/响应模型
4. 添加转写任务相关的请求/响应模型
5. 实现录音管理API方法
6. 实现音频管理API方法
7. 实现语音转文字API方法
8. 更新现有的转写相关方法，使其符合新的API规范

## 4. 注意事项
- 确保所有API请求都使用正确的HTTP方法和请求头
- 确保所有API响应都正确解析，处理成功和失败情况
- 确保文件上传功能支持multipart/form-data格式
- 确保转写任务的提交和状态查询功能正常工作

## 5. 测试计划
修改完成后，需要测试所有API方法是否能正常工作，包括：
- 音频上传
- 录音记录创建
- 转写任务提交
- 转写状态查询
- 录音列表获取
- 录音详情获取
- 录音标题更新
- 录音删除

通过这些测试，确保API服务层能够正确与后端进行交互，为客户端提供可靠的API服务。