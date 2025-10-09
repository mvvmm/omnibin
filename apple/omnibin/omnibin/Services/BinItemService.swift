import SwiftUI
import UIKit
import UniformTypeIdentifiers

@MainActor
class BinItemService: ObservableObject {
    
    func copyItem(item: BinItem, accessToken: String?) async -> (success: Bool, message: String) {
        if item.isText, let textItem = item.textItem {
            UIPasteboard.general.string = textItem.content
            return (true, "Text copied to clipboard")
        } else if item.isFile {
            return await copyFileToClipboard(item: item, accessToken: accessToken)
        }
        return (false, "Unable to copy item")
    }
    
    func downloadItem(item: BinItem, accessToken: String?) async -> (success: Bool, message: String, exportData: (Data, String, UTType)?) {
        guard item.isFile, let token = accessToken else { 
            return (false, "No access token available", nil) 
        }
        
        do {
            let downloadURL = try await BinAPI.shared.getFileDownloadURL(itemId: item.id, accessToken: token)
            if item.fileItem?.contentType.hasPrefix("image/") == true {
                // For images, return the data for Photos saving
                let (data, _) = try await URLSession.shared.data(from: URL(string: downloadURL)!)
                if let image = UIImage(data: data) {
                    return (true, "Image ready for saving", (data, item.fileItem?.originalName ?? "image", .png))
                } else {
                    return (false, "Failed to decode image", nil)
                }
            } else {
                // For non-images, return data for file export
                let (tmp, _) = try await URLSession.shared.download(from: URL(string: downloadURL)!)
                let data = try Data(contentsOf: tmp)
                let name = item.fileItem?.originalName ?? "download"
                let ext = (name as NSString).pathExtension
                let type = UTType(filenameExtension: ext) ?? .data
                return (true, "File ready for export", (data, name, type))
            }
        } catch {
            return (false, "Failed: \(error.localizedDescription)", nil)
        }
    }
    
    func deleteItem(item: BinItem, accessToken: String?) async -> (success: Bool, message: String) {
        guard let token = accessToken else {
            return (false, "No access token available")
        }
        
        do {
            try await BinAPI.shared.deleteItem(itemId: item.id, accessToken: token)
            return (true, "Item deleted successfully")
        } catch {
            return (false, "Failed to delete item: \(error.localizedDescription)")
        }
    }
    
    private func copyFileToClipboard(item: BinItem, accessToken: String?) async -> (success: Bool, message: String) {
        guard let token = accessToken else { 
            return (false, "No access token available") 
        }
        
        do {
            let downloadURL = try await BinAPI.shared.getFileDownloadURL(itemId: item.id, accessToken: token)
            guard let url = URL(string: downloadURL) else {
                return (false, "Invalid download URL")
            }
            
            let isImage = item.fileItem?.contentType.hasPrefix("image/") == true
            if isImage {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    UIPasteboard.general.image = image
                    return (true, "Image copied to clipboard")
                } else {
                    return (false, "Failed to decode image")
                }
            } else {
                let (tmpURL, _) = try await URLSession.shared.download(from: url)
                let filename = item.fileItem?.originalName ?? "file"
                
                if let provider = createFileProvider(from: tmpURL, filename: filename) {
                    UIPasteboard.general.setItemProviders([provider], localOnly: false, expirationDate: Date().addingTimeInterval(3600))
                    return (true, "File copied to clipboard")
                } else {
                    return (false, "Failed to prepare file for clipboard")
                }
            }
        } catch {
            return (false, "Failed to copy file: \(error.localizedDescription)")
        }
    }
}
