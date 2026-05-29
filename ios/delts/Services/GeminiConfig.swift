import Foundation

enum GeminiConfig {
    static let modelName = "gemini-2.5-flash"

    static var apiKey: String? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String else {
            return nil
        }
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    static var hasAPIKey: Bool {
        apiKey != nil
    }
}
