import Foundation

// API响应结果枚举
enum APIResult<T> {
    case success(T)
    case failure(Error)
}

// 统一API响应模型
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String
    let errorCode: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
        case errorCode = "error_code"
    }
    
    // 特殊处理Void类型的解码
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.success = try container.decode(Bool.self, forKey: .success)
        self.message = try container.decode(String.self, forKey: .message)
        self.errorCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
        
        // 解码data字段
        self.data = try container.decodeIfPresent(T.self, forKey: .data)
    }
}

// 录音相关模型
extension APIService {
    // 录音创建请求
    struct CreateRecordRequest: Codable {
        let title: String
        let audio_url: String
        let duration: Double
        
        enum CodingKeys: String, CodingKey {
            case title
            case audio_url
            case duration
        }
    }
    
    // 录音标题更新请求
    struct UpdateTitleRequest: Codable {
        let title: String
    }
    
    // 录音列表响应
    struct RecordListResponse: Codable {
        let total: Int
        let records: [RecordItem]
        
        // 单个录音项
        struct RecordItem: Codable {
            let id: String
            let title: String
            let audio_url: String
            let text: String?
            let duration: Double
            let created_at: String
            let updated_at: String
            let is_transcribed: Bool
            let transcription_status: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case title
                case audio_url
                case text
                case duration
                case created_at
                case updated_at
                case is_transcribed
                case transcription_status
            }
        }
    }
}

// 音频相关模型
extension APIService {
    // 音频上传响应
    struct AudioUploadResponse: Codable {
        let audio_url: String
        let file_name: String
    }
}

// 转写相关模型
extension APIService {
    // 提交转写任务请求
    struct SubmitTranscribeRequest: Codable {
        let record_id: String
        let audio_url: String
    }
    
    // 转写任务响应
    struct TranscribeTaskResponse: Codable {
        let task_id: String
        let status: String
        let record_id: String
    }
    
    // 转写状态查询响应
    struct TranscribeStatusResponse: Codable {
        let task_id: String
        let status: String
        let text: String?
    }
    
    // 录音转写结果响应
    struct RecordTranscribeResponse: Codable {
        let task_id: String
        let status: String
        let text: String?
        let record_id: String
    }
}

// API服务层
class APIService {
    static let shared = APIService()
    
    private let baseURL = "http://localhost:8000/api"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - 录音管理API
    
    // 获取录音列表
    func getRecords(page: Int = 1, limit: Int = 10, search: String? = nil, completion: @escaping (APIResult<RecordListResponse>) -> Void) {
        var urlString = "\(baseURL)/records?page=\(page)&limit=\(limit)"
        if let search = search, !search.isEmpty {
            urlString.append("&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        executeRequest(request: request, completion: completion)
    }
    
    // 获取录音详情
    func getRecordDetail(recordId: String, completion: @escaping (APIResult<RecordListResponse.RecordItem>) -> Void) {
        guard let url = URL(string: "\(baseURL)/records/\(recordId)") else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        executeRequest(request: request, completion: completion)
    }
    
    // 创建录音记录
    func createRecord(title: String, audioURL: String, duration: Double, completion: @escaping (APIResult<RecordListResponse.RecordItem>) -> Void) {
        guard let url = URL(string: "\(baseURL)/records") else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let createRecordRequest = CreateRecordRequest(title: title, audio_url: audioURL, duration: duration)
        do {
            request.httpBody = try JSONEncoder().encode(createRecordRequest)
        } catch {
            completion(.failure(error))
            return
        }
        
        executeRequest(request: request, completion: completion)
    }
    
    // 更新录音标题
    func updateRecordTitle(recordId: String, title: String, completion: @escaping (APIResult<RecordListResponse.RecordItem>) -> Void) {
        guard let url = URL(string: "\(baseURL)/records/\(recordId)/title") else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let updateTitleRequest = UpdateTitleRequest(title: title)
        do {
            request.httpBody = try JSONEncoder().encode(updateTitleRequest)
        } catch {
            completion(.failure(error))
            return
        }
        
        executeRequest(request: request, completion: completion)
    }
    
    // 删除录音
    func deleteRecord(recordId: String, completion: @escaping (APIResult<Bool>) -> Void) {
        guard let url = URL(string: "\(baseURL)/records/\(recordId)") else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无数据返回"])))
                    return
                }
                return
            }
            
            do {
                // 直接解析APIResponse，不指定泛型类型
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                if let jsonDict = jsonObject as? [String: Any] {
                    let success = jsonDict["success"] as? Bool ?? false
                    let message = jsonDict["message"] as? String ?? ""
                    
                    if success {
                        DispatchQueue.main.async {
                            completion(.success(true))
                        }
                    } else {
                        let error = NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                } else {
                    let error = NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的响应格式"])
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - 音频管理API
    
    // 上传音频文件
    func uploadAudio(fileURL: URL, completion: @escaping (APIResult<AudioUploadResponse>) -> Void) {
        guard let url = URL(string: "\(baseURL)/audio/upload") else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        do {
            let data = try createMultipartFormData(fileURL: fileURL, boundary: boundary)
            request.httpBody = data
            
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无数据返回"])))
                    }
                    return
                }
                
                do {
                    let apiResponse = try JSONDecoder().decode(APIResponse<AudioUploadResponse>.self, from: data)
                    if apiResponse.success, let data = apiResponse.data {
                        DispatchQueue.main.async {
                            completion(.success(data))
                        }
                    } else {
                        let error = NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: apiResponse.message])
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
            
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    // 下载音频文件
    func downloadAudio(fileName: String, completion: @escaping (APIResult<Data>) -> Void) {
        guard let url = URL(string: "\(baseURL)/audio/\(fileName)") else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无数据返回"])))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(data))
            }
        }
        
        task.resume()
    }
    
    // MARK: - 语音转文字API
    
    // 提交转写任务
    func submitTranscribeTask(recordId: String, audioURL: String, completion: @escaping (APIResult<TranscribeTaskResponse>) -> Void) {
        guard let url = URL(string: "\(baseURL)/transcribe/") else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let submitRequest = SubmitTranscribeRequest(record_id: recordId, audio_url: audioURL)
        do {
            request.httpBody = try JSONEncoder().encode(submitRequest)
        } catch {
            completion(.failure(error))
            return
        }
        
        executeRequest(request: request, completion: completion)
    }
    
    // 查询转写状态
    func checkTranscribeStatus(taskId: String, completion: @escaping (APIResult<TranscribeStatusResponse>) -> Void) {
        guard let url = URL(string: "\(baseURL)/transcribe/\(taskId)") else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        executeRequest(request: request, completion: completion)
    }
    
    // 获取录音转写结果
    func getRecordTranscription(recordId: String, completion: @escaping (APIResult<RecordTranscribeResponse>) -> Void) {
        guard let url = URL(string: "\(baseURL)/transcribe/record/\(recordId)") else {
            completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        executeRequest(request: request, completion: completion)
    }
    
    // MARK: - 辅助方法
    
    // 执行通用API请求
    private func executeRequest<T: Codable>(request: URLRequest, completion: @escaping (APIResult<T>) -> Void) {
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无数据返回"])))
                }
                return
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
                if apiResponse.success, let data = apiResponse.data {
                    DispatchQueue.main.async {
                        completion(.success(data))
                    }
                } else {
                    let error = NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: apiResponse.message])
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    // 创建multipart/form-data数据
    private func createMultipartFormData(fileURL: URL, boundary: String) throws -> Data {
        var data = Data()
        
        // 添加文件字段
        let fileName = fileURL.lastPathComponent
        data.append("--\(boundary)\r\n".data(using: .utf8)!)  
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)  
        
        // 根据文件扩展名设置Content-Type
        let mimeType: String
        let fileExtension = fileName.lowercased().split(separator: ".").last ?? ""
        switch fileExtension {
        case "m4a":
            mimeType = "audio/m4a"
        case "mp4":
            mimeType = "audio/mp4"
        case "wav":
            mimeType = "audio/wav"
        default:
            mimeType = "application/octet-stream"
        }
        
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)  
        data.append(try Data(contentsOf: fileURL))
        data.append("\r\n".data(using: .utf8)!)  
        
        // 结束boundary
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)  
        
        return data
    }
}
