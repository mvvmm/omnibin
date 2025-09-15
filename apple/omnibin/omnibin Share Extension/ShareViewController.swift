import UIKit
import Social
import Foundation

class ShareViewController: UIViewController {
    
    private var isProcessing = false
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let cancelButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        processContentAutomatically()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Setup activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        // Setup status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "Adding to omnibin..."
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(statusLabel)
        
        // Setup cancel button
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 30)
        ])
    }
    
    private func processContentAutomatically() {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        // Process the content immediately
        processContent { [weak self] success in
            Task { @MainActor in
                self?.isProcessing = false
                if success {
                    self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                } else {
                    self?.statusLabel.text = "Failed to add content"
                    self?.activityIndicator.stopAnimating()
                    self?.cancelButton.setTitle("Close", for: .normal)
                }
            }
        }
    }
    
    @objc private func cancelTapped() {
        extensionContext?.cancelRequest(withError: NSError(domain: "ShareExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "User cancelled"]))
    }
    
    private func processContent(completion: @escaping (Bool) -> Void) {
        // Get attachments
        guard let inputItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            completion(false)
            return
        }
        
        // Process attachments
        guard let attachments = inputItem.attachments, !attachments.isEmpty else {
            completion(false)
            return
        }
        
        // Process the first attachment
        let attachment = attachments[0]
        
        // Check for image first (most common case for Photos sharing)
        if attachment.hasItemConformingToTypeIdentifier("public.image") {
            attachment.loadItem(forTypeIdentifier: "public.image", options: nil) { [weak self] (item, error) in
                if error != nil {
                    completion(false)
                    return
                }
                
                if let image = item as? UIImage {
                    self?.addImageToBin(image, completion: completion)
                } else if let url = item as? URL {
                    self?.addImageFromURL(url, completion: completion)
                } else if let data = item as? Data {
                    self?.addImageFromData(data, completion: completion)
                } else {
                    completion(false)
                }
            }
        } else if attachment.hasItemConformingToTypeIdentifier("public.url") {
            attachment.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] (item, error) in
                if let url = item as? URL {
                    self?.addURLToBin(url, completion: completion)
                } else {
                    completion(false)
                }
            }
        } else {
            // Try to get as text
            attachment.loadItem(forTypeIdentifier: "public.text", options: nil) { [weak self] (item, error) in
                if let text = item as? String {
                    self?.addTextToBin(text, completion: completion)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    private func addTextToBin(_ text: String, completion: @escaping (Bool) -> Void) {
        // Get access token from shared container
        guard let accessToken = getAccessToken() else {
            Task { @MainActor in
                self.statusLabel.text = "Not logged in"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }
        
        // Make API call to add text item
        Task {
            do {
                let _ = try await addTextItemToAPI(content: text, accessToken: accessToken)
                await callCompletion(true, completion: completion)
            } catch {
                await self.setStatusAndStopAnimating("Upload failed")
                await callCompletion(false, completion: completion)
            }
        }
    }
    
    private func addURLToBin(_ url: URL, completion: @escaping (Bool) -> Void) {
        // Add URL as text for now
        addTextToBin(url.absoluteString, completion: completion)
    }
    
    private func addImageToBin(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        // Get access token from shared container
        guard let accessToken = getAccessToken() else {
            Task { @MainActor in
                self.statusLabel.text = "Not logged in"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }
        
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            Task { @MainActor in
                self.statusLabel.text = "Failed to process image"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }
        
        // Check if image data is too large
        let maxSize = 10 * 1024 * 1024 // 10MB
        if imageData.count > maxSize {
            Task { @MainActor in
                self.statusLabel.text = "Image too large"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }
        
        // Get image dimensions
        let imageWidth = Int(image.size.width)
        let imageHeight = Int(image.size.height)
        
        // Generate a filename
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "shared_image_\(timestamp).jpg"
        
        // Make API call to add file item
        Task {
            do {
                let _ = try await addFileItemToAPI(
                    fileData: imageData,
                    originalName: filename,
                    contentType: "image/jpeg",
                    imageWidth: imageWidth,
                    imageHeight: imageHeight,
                    accessToken: accessToken
                )
                await callCompletion(true, completion: completion)
            } catch {
                await self.setStatusAndStopAnimating("Upload failed")
                await callCompletion(false, completion: completion)
            }
        }
    }
    
    private func addImageFromURL(_ url: URL, completion: @escaping (Bool) -> Void) {
        // Get access token from shared container
        guard getAccessToken() != nil else {
            DispatchQueue.main.async {
                self.statusLabel.text = "Not logged in"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }
        
        // Check if it's a local file URL (from Photos app)
        if url.isFileURL {
            loadLocalImage(from: url, completion: completion)
        } else {
            loadRemoteImage(from: url, completion: completion)
        }
    }
    
    private func loadLocalImage(from url: URL, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                // For local files, we need to use the security-scoped URL
                let securityScopedResource = url.startAccessingSecurityScopedResource()
                defer {
                    if securityScopedResource {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                let data = try Data(contentsOf: url)
                
                guard let image = UIImage(data: data) else {
                    await self.setStatusAndStopAnimating("Invalid image data")
                    completion(false)
                    return
                }
                
                // Update UI on main actor
                await self.callAddImage(image, completion: completion)
                
            } catch {
                await self.setStatusAndStopAnimating("Failed to load image")
                completion(false)
            }
        }
    }
    
    private func loadRemoteImage(from url: URL, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    await self.setStatusAndStopAnimating("Failed to load image")
                    completion(false)
                    return
                }
                
                guard let image = UIImage(data: data) else {
                    await self.setStatusAndStopAnimating("Invalid image data")
                    completion(false)
                    return
                }
                
                // Update UI on main actor
                await self.callAddImage(image, completion: completion)
                
            } catch {
                await self.setStatusAndStopAnimating("Failed to load image")
                completion(false)
            }
        }
    }
    
    private func addImageFromData(_ data: Data, completion: @escaping (Bool) -> Void) {
        guard let image = UIImage(data: data) else {
            Task { @MainActor in
                self.statusLabel.text = "Invalid image data"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }
        
        addImageToBin(image, completion: completion)
    }
    
    private func addImageURLToBin(_ url: URL, completion: @escaping (Bool) -> Void) {
        // Add image URL as text
        addTextToBin(url.absoluteString, completion: completion)
    }
    
    // MARK: - MainActor helpers
    @MainActor
    private func setStatusAndStopAnimating(_ message: String) async {
        self.statusLabel.text = message
        self.activityIndicator.stopAnimating()
    }

    @MainActor
    private func callCompletion(_ success: Bool, completion: @escaping (Bool) -> Void) async {
        completion(success)
    }

    @MainActor
    private func callAddImage(_ image: UIImage, completion: @escaping (Bool) -> Void) async {
        self.addImageToBin(image, completion: completion)
    }
    // MARK: - API Integration
    
    private func getAccessToken() -> String? {
        // Try keychain first
        let token = SecureStorageManager.shared.getAccessToken()
        if let token = token {
            return token
        }
        
        // Fallback to UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.in.omnib.omnibin")
        return sharedDefaults?.string(forKey: "access_token")
    }
    
    private func addTextItemToAPI(content: String, accessToken: String) async throws -> BinItem {
        guard let url = URL(string: "https://www.omnib.in/api/bin") else {
            throw NSError(domain: "ShareExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ShareExtension", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            throw NSError(domain: "ShareExtension", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode) - \(responseString)"])
        }
        
        // Parse response to BinItem
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let itemData = json else {
            throw NSError(domain: "ShareExtension", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        // Create a simple BinItem from the response
        return BinItem(
            id: itemData["id"] as? String ?? UUID().uuidString,
            createdAt: itemData["createdAt"] as? String ?? "",
            textItem: TextItem(content: content),
            fileItem: nil
        )
    }
    
    private func addFileItemToAPI(fileData: Data, originalName: String, contentType: String, imageWidth: Int?, imageHeight: Int?, accessToken: String) async throws -> BinItem {
        guard let url = URL(string: "https://www.omnib.in/api/bin") else {
            throw NSError(domain: "ShareExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Step 1: Request upload URL from server
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var fileMetadata: [String: Any] = [
            "originalName": originalName,
            "contentType": contentType,
            "size": fileData.count
        ]
        
        // Only add image dimensions if they are valid
        if let width = imageWidth, width > 0 {
            fileMetadata["imageWidth"] = width
        }
        if let height = imageHeight, height > 0 {
            fileMetadata["imageHeight"] = height
        }
        
        let requestBody = ["file": fileMetadata]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ShareExtension", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? "Unknown error"
            throw NSError(domain: "ShareExtension", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "\(errorMessage) - \(responseString)"])
        }
        
        let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let uploadURLString = responseData?["uploadUrl"] as? String,
              let uploadURL = URL(string: uploadURLString) else {
            throw NSError(domain: "ShareExtension", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid upload URL"])
        }
        
        // Step 2: Upload file to S3
        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.httpMethod = "PUT"
        uploadRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        uploadRequest.httpBody = fileData
        
        let (_, uploadResponse) = try await URLSession.shared.data(for: uploadRequest)
        
        guard let uploadHttpResponse = uploadResponse as? HTTPURLResponse else {
            throw NSError(domain: "ShareExtension", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid upload response"])
        }
        
        guard (200...299).contains(uploadHttpResponse.statusCode) else {
            throw NSError(domain: "ShareExtension", code: uploadHttpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to upload file to storage"])
        }
        
        // Step 3: Parse and return the BinItem
        guard let itemData = responseData?["item"] as? [String: Any] else {
            throw NSError(domain: "ShareExtension", code: -5, userInfo: [NSLocalizedDescriptionKey: "Invalid item data"])
        }
        
        // Create a simple BinItem from the response
        return BinItem(
            id: itemData["id"] as? String ?? UUID().uuidString,
            createdAt: itemData["createdAt"] as? String ?? "",
            textItem: nil,
            fileItem: FileItem(
                originalName: originalName,
                contentType: contentType,
                size: fileData.count
            )
        )
    }

}

// MARK: - Simplified Models for Share Extension

struct BinItem {
    let id: String
    let createdAt: String
    let textItem: TextItem?
    let fileItem: FileItem?
}

struct TextItem {
    let content: String
}

struct FileItem {
    let originalName: String
    let contentType: String
    let size: Int
}