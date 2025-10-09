import Foundation

// MARK: - File Upload Service
class FileUploadService {
    static let shared = FileUploadService()
    
    private let networkClient = NetworkClient.shared
    private let authService = AuthenticationService.shared
    private let networkConfig = NetworkConfiguration.shared
    
    private init() {}
    
    // MARK: - Add File Item
    func addFileItem(
        fileData: Data,
        originalName: String,
        contentType: String,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        accessToken: String
    ) async throws -> BinItem {
        do {
            return try await performAddFileItem(
                fileData: fileData,
                originalName: originalName,
                contentType: contentType,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                accessToken: accessToken
            )
        } catch BinAPIError.httpError(401, _) {
            // Token might be expired, try to refresh
            let refreshedToken = try await authService.refreshTokenIfNeeded()
            return try await performAddFileItem(
                fileData: fileData,
                originalName: originalName,
                contentType: contentType,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                accessToken: refreshedToken
            )
        }
    }
    
    private func performAddFileItem(
        fileData: Data,
        originalName: String,
        contentType: String,
        imageWidth: Int?,
        imageHeight: Int?,
        accessToken: String
    ) async throws -> BinItem {
        // Step 1: Request upload URL from server
        let headers = ["Authorization": "Bearer \(accessToken)"]
        
        let fileMetadata: [String: Any] = [
            "originalName": originalName,
            "contentType": contentType,
            "size": fileData.count,
            "imageWidth": imageWidth as Any,
            "imageHeight": imageHeight as Any
        ]
        
        let requestBody = ["file": fileMetadata]
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await networkClient.makeRequest(
            endpoint: networkConfig.binEndpoint,
            method: .POST,
            headers: headers,
            body: bodyData
        )
        
        let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let uploadURLString = responseData?["uploadUrl"] as? String,
              let uploadURL = URL(string: uploadURLString) else {
            throw BinAPIError.invalidResponse
        }
        
        // Step 2: Upload file to S3
        try await uploadFileToS3(fileData: fileData, contentType: contentType, uploadURL: uploadURL)
        
        // Step 3: Parse and return the BinItem
        guard let itemData = responseData?["item"] as? [String: Any] else {
            throw BinAPIError.invalidResponse
        }
        
        let itemJSON = try JSONSerialization.data(withJSONObject: itemData)
        return try JSONDecoder().decode(BinItem.self, from: itemJSON)
    }
    
    private func uploadFileToS3(fileData: Data, contentType: String, uploadURL: URL) async throws {
        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.httpMethod = "PUT"
        uploadRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        uploadRequest.httpBody = fileData
        
        let (_, uploadResponse) = try await URLSession.shared.data(for: uploadRequest)
        
        guard let uploadHttpResponse = uploadResponse as? HTTPURLResponse else {
            throw BinAPIError.invalidResponse
        }
        
        guard (200...299).contains(uploadHttpResponse.statusCode) else {
            throw BinAPIError.httpError(uploadHttpResponse.statusCode, message: "Failed to upload file to storage")
        }
    }
}
