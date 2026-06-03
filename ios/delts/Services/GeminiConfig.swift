import Foundation

enum GeminiConfig {
    static let modelName = "gemini-2.5-flash"

    static var apiKey: String? {
        normalizedAPIKey(Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String)
            ?? bundledSecretAPIKey
    }

    static var hasAPIKey: Bool {
        apiKey != nil
    }

    private static var bundledSecretAPIKey: String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let values = plist as? [String: Any] else {
            return nil
        }
        return normalizedAPIKey(values["GEMINI_API_KEY"] as? String)
    }

    private static func normalizedAPIKey(_ value: String?) -> String? {
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
