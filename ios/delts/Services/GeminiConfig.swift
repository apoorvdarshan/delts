import Foundation

enum GeminiConfig {
    static var apiKey: String? {
        return LocalGeminiKeyStore.apiKey
    }

    static var hasAPIKey: Bool {
        apiKey != nil
    }
}
