import Foundation
import UniformTypeIdentifiers

// MARK: - Content Type Detection

/// Detect content type from data using magic bytes
func detectContentType(from data: Data) -> (mime: String, ext: String) {
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    let pngSig: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    if data.count >= pngSig.count && data.prefix(pngSig.count).elementsEqual(pngSig) {
        return ("image/png", "png")
    }
    // JPEG: FF D8 FF
    let jpegSig: [UInt8] = [0xFF, 0xD8, 0xFF]
    if data.count >= jpegSig.count && data.prefix(jpegSig.count).elementsEqual(jpegSig) {
        return ("image/jpeg", "jpg")
    }
    // GIF: 47 49 46 38
    let gifSig: [UInt8] = [0x47, 0x49, 0x46, 0x38]
    if data.count >= gifSig.count && data.prefix(gifSig.count).elementsEqual(gifSig) {
        return ("image/gif", "gif")
    }
    // WebP: RIFF....WEBP
    if data.count >= 12 {
        let riff = data.prefix(4)
        let webp = data.dropFirst(8).prefix(4)
        if Array(riff) == [0x52, 0x49, 0x46, 0x46] && Array(webp) == [0x57, 0x45, 0x42, 0x50] {
            return ("image/webp", "webp")
        }
    }
    // HEIF/HEIC: ftypheic/heix/heim/heis or mif1
    if data.count >= 12 {
        let box = data.dropFirst(4).prefix(4) // 'ftyp'
        if Array(box) == [0x66, 0x74, 0x79, 0x70] {
            let brand = data.dropFirst(8).prefix(4)
            let brandStr = String(bytes: brand, encoding: .ascii) ?? ""
            if ["heic","heix","heim","heis","mif1","msf1"].contains(brandStr) {
                return ("image/heic", "heic")
            }
        }
    }
    
    // PDF: %PDF
    if data.count >= 4 {
        let bytes = Array(data.prefix(4))
        if bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46 {
            return ("application/pdf", "pdf")
        }
    }
    
    // ZIP: PK 03 04
    if data.count >= 4 {
        let bytes = Array(data.prefix(4))
        if bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04 {
            return ("application/zip", "zip")
        }
    }
    
    return ("application/octet-stream", "bin")
}

/// Detect content type from file URL - tries extension first, then magic bytes
func detectContentType(from data: Data, url: URL) -> String {
    let ext = url.pathExtension.lowercased()
    
    // Try to get content type from UTType first (most reliable for known extensions)
    if !ext.isEmpty, let utType = UTType(filenameExtension: ext), let mimeType = utType.preferredMIMEType {
        return mimeType
    }
    
    // Fallback: check file signature (magic bytes) for files without extensions
    let detection = detectContentType(from: data)
    return detection.mime
}
