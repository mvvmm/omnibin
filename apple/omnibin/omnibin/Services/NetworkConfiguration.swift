import Foundation

// MARK: - Network Configuration Service
class NetworkConfiguration {
    static let shared = NetworkConfiguration()
    
    private init() {}
    
    // Base URL for the backend. Defaults to production, but can be overridden for dev/testing.
    var baseURL: String {
        // 1) Runtime override via UserDefaults (useful for QA toggles)
        if let override = UserDefaults.standard.string(forKey: "OMNIBIN_BASE_URL"), !override.isEmpty {
            return override
        }
        // 2) Info.plist key (set per build configuration)
        if let fromPlist = Bundle.main.object(forInfoDictionaryKey: "OMNIBIN_BASE_URL") as? String, !fromPlist.isEmpty {
            return fromPlist
        }
        // 3) Debug env var for simulators
        #if DEBUG
        if let fromEnv = ProcessInfo.processInfo.environment["OMNIBIN_BASE_URL"], !fromEnv.isEmpty {
            return fromEnv
        }
        #endif
        // 4) Fallback to production
        return "https://www.omnib.in"
    }
    
    let binEndpoint = "/api/bin"
    let ogEndpoint = "/api/og"
    
    func createURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "omnibin-ios/1.0"
        ]
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache.shared
        return URLSession(configuration: config)
    }
}
