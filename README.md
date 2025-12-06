# VoiceNotes

VoiceNotes 是一个功能强大的 iOS 语音笔记应用，支持录音、音频播放、自动转录和云同步功能。

## 功能特性

- 🎙️ **语音录制**：高质量音频录制，支持暂停/继续录制
- 🎵 **音频播放**：内置音频播放器，支持播放、暂停、快进、快退
- 📝 **自动转录**：集成 AI 转录服务，将语音转换为文本
- ☁️ **云同步**：与 FastAPI 后端集成，实现数据同步
- 📱 **优雅 UI**：现代化 SwiftUI 界面设计，流畅的用户体验
- 🔄 **实时更新**：转录状态实时更新，支持手动刷新
- 📋 **笔记管理**：支持编辑标题、查看详情、删除笔记

## 技术栈

### 前端 (iOS)
- **开发语言**：Swift 5.0+
- **UI 框架**：SwiftUI
- **音频处理**：AVFoundation
- **API 集成**：URLSession
- **数据存储**：本地 JSON 文件 + 云存储

### 后端
- **框架**：FastAPI (Python)
- **数据库**：SQLite/PostgreSQL
- **音频转录**：集成第三方转录服务

## 架构设计

### 核心组件

1. **APIService**：处理与后端的所有 API 通信
2. **AudioRecorder**：管理音频录制功能
3. **AudioPlayer**：处理音频播放
4. **DataManager**：本地数据存储和管理
5. **VoiceRecord**：录音数据模型

### 主要视图

- **ContentView**：应用主界面，显示录音列表
- **RecordingView**：录音界面，控制录制过程
- **DetailView**：录音详情，显示转录文本和播放控制

### API 流程

1. **录音完成**：
   - 停止录制并获取音频文件
   - 上传音频到服务器
   - 创建录音记录
   - 提交转录请求
   - 轮询转录状态

2. **数据同步**：
   - 定期同步本地数据到云端
   - 从云端拉取最新数据
   - 处理冲突和错误

## 安装和运行

### 前置条件

- Xcode 14.0+
- iOS 15.0+
- Python 3.8+ (用于后端开发)

### 前端安装

1. 克隆仓库：
   ```bash
   git clone https://github.com/2358723997/VoiceNotes.git
   ```

2. 打开项目：
   ```bash
   cd VoiceNotes
   open VoiceNotes.xcodeproj
   ```

3. 运行应用：
   - 选择模拟器或真实设备
   - 点击 Xcode 运行按钮

### 后端安装

1. 进入后端目录：
   ```bash
   cd VoiceNotesBackend
   ```

2. 安装依赖：
   ```bash
   pip install -r requirements.txt
   ```

3. 启动服务器：
   ```bash
   uvicorn main:app --reload
   ```

## 主要文件说明

| 文件 | 功能 |
|------|------|
| `APIService.swift` | 处理与 FastAPI 后端的通信 |
| `AudioPlayer.swift` | 音频播放功能实现 |
| `AudioRecorder.swift` | 音频录制功能实现 |
| `ContentView.swift` | 应用主界面，显示录音列表 |
| `DataManager.swift` | 本地数据存储和管理 |
| `DetailView.swift` | 录音详情界面 |
| `Record.swift` | 录音数据模型定义 |
| `RecordingView.swift` | 录音控制界面 |
| `VoiceNotesApp.swift` | 应用入口 |

## API 端点

### 音频相关
- `POST /api/audios/` - 上传音频文件
- `GET /api/audios/{id}` - 获取音频详情

### 录音相关
- `POST /api/records/` - 创建录音记录
- `GET /api/records/` - 获取录音列表
- `GET /api/records/{id}` - 获取录音详情
- `PUT /api/records/{id}` - 更新录音记录
- `DELETE /api/records/{id}` - 删除录音记录

### 转录相关
- `POST /api/transcriptions/` - 提交转录请求
- `GET /api/transcriptions/{id}` - 获取转录详情

## 开发流程

1. 创建功能分支
2. 实现新功能或修复 bug
3. 运行测试确保功能正常
4. 提交代码并创建 PR
5. 代码审查通过后合并到主分支

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

*Made with ❤️ for iOS Development*