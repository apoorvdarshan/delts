import Foundation
import UIKit

/// A single message in the Coach conversation.
struct CoachMessage: Identifiable {
    enum Role {
        case user
        case model
    }

    let id: UUID
    let role: Role
    var text: String
    var image: UIImage?
    var isError: Bool

    init(id: UUID = UUID(), role: Role, text: String, image: UIImage? = nil, isError: Bool = false) {
        self.id = id
        self.role = role
        self.text = text
        self.image = image
        self.isError = isError
    }
}

enum CoachServiceError: LocalizedError {
    case notConfigured
    case network
    case server(Int)
    case empty

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return String(localized: "Coach isn't available right now.")
        case .network:
            return String(localized: "Network error. Check your connection and try again.")
        case .server(let code):
            if code == 503 {
                return String(localized: "Coach AI isn't set up on the server yet.")
            }
            return String(localized: "Coach request failed (\(code)). Try again.")
        case .empty:
            return String(localized: "Coach didn't return a response. Try rephrasing.")
        }
    }
}

/// Talks to the delts.fit Gemini proxy for the Coach chat. The API key lives
/// server-side as a Vercel env var, so nothing sensitive ships in the app.
final class CoachService {
    func reply(systemContext: String, history: [CoachMessage]) async throws -> String {
        guard let url = GeminiConfig.proxyURL else {
            throw CoachServiceError.notConfigured
        }

        var contents: [[String: Any]] = []
        for message in history {
            var parts: [[String: Any]] = []
            let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                parts.append(["text": text])
            }
            if let image = message.image, let base64 = Self.encodedJPEG(image) {
                parts.append(["inlineData": ["mimeType": "image/jpeg", "data": base64]])
            }
            guard !parts.isEmpty else { continue }
            contents.append([
                "role": message.role == .user ? "user" : "model",
                "parts": parts
            ])
        }

        let payload: [String: Any] = [
            "systemInstruction": ["parts": [["text": systemContext]]],
            "contents": contents,
            "generationConfig": ["temperature": 0.6, "topP": 0.95]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(GeminiConfig.deviceID, forHTTPHeaderField: "X-Delts-Device")
        request.timeoutInterval = 60
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CoachServiceError.network
        }

        guard let http = response as? HTTPURLResponse else {
            throw CoachServiceError.network
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CoachServiceError.server(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(CoachGeminiResponse.self, from: data)
        let text = decoded.candidates?
            .first?
            .content?
            .parts?
            .compactMap { $0.text }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !text.isEmpty else {
            throw CoachServiceError.empty
        }
        return text
    }

    /// Downscale + JPEG-compress so multimodal payloads (and stored history) stay small.
    static func jpegData(_ image: UIImage, maxDimension: CGFloat = 1024) -> Data? {
        let resized = resize(image, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: 0.6)
    }

    static func encodedJPEG(_ image: UIImage, maxDimension: CGFloat = 1024) -> String? {
        jpegData(image, maxDimension: maxDimension)?.base64EncodedString()
    }

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return image }

        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

private struct CoachGeminiResponse: Decodable {
    let candidates: [Candidate]?

    struct Candidate: Decodable {
        let content: Content?
    }

    struct Content: Decodable {
        let parts: [Part]?
    }

    struct Part: Decodable {
        let text: String?
    }
}
