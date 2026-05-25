import Foundation

enum GeminiConfig {
    static var apiKey: String? {
        let selectedProvider = UserDefaults.standard.string(forKey: "profile_ai_provider") ?? "Gemini"
        guard selectedProvider == "Gemini" else {
            return nil
        }
        return LocalGeminiKeyStore.apiKey
    }

    static var hasAPIKey: Bool {
        apiKey != nil
    }
}
