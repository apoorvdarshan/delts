import Foundation

enum GeminiConfig {
    static let modelName = "gemini-2.5-flash"

    /// All Gemini access is routed through the delts.fit server-side proxy, which
    /// holds the API key as a Vercel environment variable. The app never ships a key.
    /// Override at runtime (e.g. for local testing) with a `GEMINI_PROXY_URL` entry
    /// in Info.plist; otherwise the production proxy is used.
    static let proxyURL: URL? = {
        if let override = (Bundle.main.object(forInfoDictionaryKey: "GEMINI_PROXY_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !override.isEmpty,
           let url = URL(string: override) {
            return url
        }
        return URL(string: "https://delts.fit/api/gemini")
    }()

    /// AI features are available whenever the proxy endpoint is configured.
    static var isAIEnabled: Bool { proxyURL != nil }
}
