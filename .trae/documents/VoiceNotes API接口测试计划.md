# VoiceNotes API接口测试计划

## 1. 测试目标
测试VoiceNotes后端API的各个接口是否能正常工作，包括录音管理、音频管理和语音转文字功能。

## 2. 测试环境
- 后端服务：FastAPI（运行在http://localhost:8000/api）
- 测试工具：curl命令行工具

## 3. 测试前准备
1. 确保后端服务已经启动
2. 准备测试用的音频文件（m4a、mp4或wav格式，大小≤10MB）

## 4. 测试用例

### 4.1 录音管理接口

#### 4.1.1 获取录音列表
```bash
curl -X GET "http://localhost:8000/api/records"
```
- 预期结果：返回录音列表，包含total和records字段

#### 4.1.2 创建录音记录
```bash
curl -X POST "http://localhost:8000/api/records" \
  -H "Content-Type: application/json" \
  -d '{"title": "测试录音", "audio_url": "https://example.com/audio.mp3", "duration": 10.5}'
```
- 预期结果：成功创建录音记录，返回创建的录音信息

### 4.2 音频管理接口

#### 4.2.1 上传音频文件
```bash
curl -X POST "http://localhost:8000/api/audio/upload" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@/path/to/test-audio.m4a"
```
- 预期结果：成功上传音频文件，返回audio_url和file_name

### 4.3 语音转文字接口

#### 4.3.1 提交转写任务
```bash
curl -X POST "http://localhost:8000/api/transcribe/" \
  -H "Content-Type: application/json" \
  -d '{"record_id": "uuid", "audio_url": "https://example.com/audio.mp3"}'
```
- 预期结果：成功提交转写任务，返回task_id和status

#### 4.3.2 查询转写状态
```bash
curl -X GET "http://localhost:8000/api/transcribe/{task_id}"
```
- 预期结果：返回转写任务的状态和结果

## 5. 测试执行步骤
1. 检查后端服务是否运行
2. 依次执行上述测试用例
3. 记录每个测试用例的结果
4. 分析测试结果，检查是否符合预期

## 6. 测试结果分析
- 成功：返回状态码200，success字段为true
- 失败：返回相应的错误码和错误信息，根据error_code进行分析

## 7. 注意事项
- 确保测试音频文件符合要求（格式、大小）
- 替换测试用例中的占位符（如file路径、record_id、task_id）
- 测试前确保后端服务已正确配置和启动