import Foundation

enum GeminiConfig {
    static var apiKey: String? {
        LocalGeminiKeyStore.apiKey
    }

    static var hasAPIKey: Bool {
        apiKey != nil
    }
}
