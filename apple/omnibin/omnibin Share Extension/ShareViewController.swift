import UIKit
import Social
import Foundation

class ShareViewController: SLComposeServiceViewController {
    
    private var isProcessing = false

    override func isContentValid() -> Bool {
        // Allow posting if we have text content or attachments
        return !contentText.isEmpty || !(extensionContext?.inputItems.isEmpty ?? true)
    }

    override func didSelectPost() {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        // Show loading state
        DispatchQueue.main.async {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            self.navigationItem.rightBarButtonItem?.title = "Adding..."
        }
        
        // Process the content
        processContent { [weak self] success in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if success {
                    // Success - close the extension
                    self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                } else {
                    // Error - show error and re-enable button
                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                    self?.navigationItem.rightBarButtonItem?.title = "Post"
                    
                    // Show error alert
                    let alert = UIAlertController(title: "Error", message: "Failed to add content to omnibin. Please try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    private func processContent(completion: @escaping (Bool) -> Void) {
        // Get the text content
        let textContent = contentText
        
        // Get attachments
        guard let inputItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            completion(false)
            return
        }
        
        // If we have text content, add it directly
        if let textContent = textContent, !textContent.isEmpty {
            addTextToBin(textContent, completion: completion)
            return
        }
        
        // Process attachments
        guard let attachments = inputItem.attachments, !attachments.isEmpty else {
            completion(false)
            return
        }
        
        // Process the first attachment
        let attachment = attachments[0]
        
        if attachment.hasItemConformingToTypeIdentifier("public.url") {
            attachment.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] (item, error) in
                if let url = item as? URL {
                    self?.addURLToBin(url, completion: completion)
                } else {
                    completion(false)
                }
            }
        } else if attachment.hasItemConformingToTypeIdentifier("public.image") {
            attachment.loadItem(forTypeIdentifier: "public.image", options: nil) { [weak self] (item, error) in
                if let image = item as? UIImage {
                    self?.addImageToBin(image, completion: completion)
                } else if let url = item as? URL {
                    self?.addImageURLToBin(url, completion: completion)
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
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Not Logged In", 
                    message: "Please open omnibin and log in first to use the Share Extension.", 
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
            completion(false)
            return
        }
        
        // Make API call to add text item
        Task {
            do {
                let _ = try await addTextItemToAPI(content: text, accessToken: accessToken)
                await MainActor.run {
                    completion(true)
                }
            } catch {
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    private func addURLToBin(_ url: URL, completion: @escaping (Bool) -> Void) {
        // Add URL as text for now
        addTextToBin(url.absoluteString, completion: completion)
    }
    
    private func addImageToBin(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        // For now, add image description as text
        // TODO: Implement actual image upload
        addTextToBin("Image shared to omnibin", completion: completion)
    }
    
    private func addImageURLToBin(_ url: URL, completion: @escaping (Bool) -> Void) {
        // Add image URL as text
        addTextToBin(url.absoluteString, completion: completion)
    }
    
    // MARK: - API Integration
    
    private func getAccessToken() -> String? {
        return SecureStorageManager.shared.getAccessToken()
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
            throw NSError(domain: "ShareExtension", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
        }
        
        // Parse response to BinItem
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let itemData = json else {
            throw NSError(domain: "ShareExtension", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        // Create a simple BinItem from the response
        // This is a simplified version - you might want to use your actual BinItem model
        return BinItem(
            id: itemData["id"] as? String ?? UUID().uuidString,
            createdAt: itemData["createdAt"] as? String ?? "",
            textItem: TextItem(content: content),
            fileItem: nil
        )
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
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