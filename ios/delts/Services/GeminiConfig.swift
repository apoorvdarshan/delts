import Foundation

enum GeminiConfig {
    /// Local setup:
    /// - Copy `ios/Secrets.example.xcconfig` to `ios/Secrets.xcconfig`.
    /// - Add `GEMINI_API_KEY = your_gemini_api_key_here` to the ignored file.
    /// - `ios/Config/Base.xcconfig` maps that value into the generated Info.plist.
    /// Do not put real API keys in Swift files or committed project files.
    static var apiKey: String? {
        let value = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !trimmed.isEmpty, !trimmed.contains("$("), !trimmed.lowercased().contains("your_gemini") else {
            return nil
        }

        return trimmed
    }

    static var hasAPIKey: Bool {
        apiKey != nil
    }
}

