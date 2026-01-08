#!/usr/bin/env swift
import Foundation
import Security

// Quick script to decode and show your access token expiration
// Usage: swift debug_token.swift

let groupIdentifier = "group.in.omnib.omnibin"

func getAccessToken() -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "omnibin_access_token",
        kSecAttrAccessGroup as String: groupIdentifier,
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status == errSecSuccess,
          let data = result as? Data,
          let token = String(data: data, encoding: .utf8) else {
        return nil
    }

    return token
}

func decodeJWT(_ token: String) -> [String: Any]? {
    let segments = token.components(separatedBy: ".")
    guard segments.count == 3 else {
        return nil
    }

    let payloadSegment = segments[1]
    var base64 = payloadSegment
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")

    let paddingLength = (4 - base64.count % 4) % 4
    base64 += String(repeating: "=", count: paddingLength)

    guard let data = Data(base64Encoded: base64),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return nil
    }

    return json
}

// Main execution
print("🔍 Checking your access token expiration...\n")

guard let token = getAccessToken() else {
    print("❌ No access token found in keychain")
    print("   Try logging in to the main app first")
    exit(1)
}

print("✅ Found access token")

guard let payload = decodeJWT(token) else {
    print("❌ Failed to decode token")
    exit(1)
}

if let exp = payload["exp"] as? TimeInterval {
    let expirationDate = Date(timeIntervalSince1970: exp)
    let now = Date()
    let timeUntilExpiration = expirationDate.timeIntervalSince(now)

    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .long

    print("📅 Token expires at: \(formatter.string(from: expirationDate))")

    if timeUntilExpiration > 0 {
        let hours = Int(timeUntilExpiration / 3600)
        let minutes = Int((timeUntilExpiration.truncatingRemainder(dividingBy: 3600)) / 60)
        print("⏱️  Time remaining: \(hours)h \(minutes)m")

        // Calculate original expiration duration
        if let iat = payload["iat"] as? TimeInterval {
            let issuedDate = Date(timeIntervalSince1970: iat)
            let totalDuration = expirationDate.timeIntervalSince(issuedDate)
            let totalHours = Int(totalDuration / 3600)
            print("⚙️  Token lifetime: \(totalHours) hours (\(Int(totalDuration)) seconds)")
        }
    } else {
        print("❌ Token is EXPIRED")
        let hoursAgo = Int(abs(timeUntilExpiration) / 3600)
        let minutesAgo = Int((abs(timeUntilExpiration).truncatingRemainder(dividingBy: 3600)) / 60)
        print("   Expired \(hoursAgo)h \(minutesAgo)m ago")
    }
} else {
    print("❌ No expiration time found in token")
}

print("\n📋 Full token payload:")
for (key, value) in payload.sorted(by: { $0.key < $1.key }) {
    print("   \(key): \(value)")
}
