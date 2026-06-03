import Foundation

final class GeminiSplitImageService {
    static let shared = GeminiSplitImageService()

    private let cacheFolderName = "GeminiWorkoutSplitImages"
    private var unavailableUntil: Date?

    func imageData(for split: WorkoutSplit) async -> Data? {
        if let cachedData = cachedImageData(for: split) {
            return cachedData
        }
        if let unavailableUntil, unavailableUntil > Date() {
            return nil
        }

        do {
            let data = try await generateImageData(for: split)
            try cacheImageData(data, for: split)
            return data
        } catch {
            unavailableUntil = Date().addingTimeInterval(60 * 60)
            return nil
        }
    }

    private func generateImageData(for split: WorkoutSplit) async throws -> Data {
        guard let apiKey = GeminiConfig.apiKey else {
            throw GeminiSplitImageError.missingAPIKey
        }
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/\(GeminiConfig.imageModelName):generateContent") else {
            throw GeminiSplitImageError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONEncoder().encode(GeminiSplitImageRequest(prompt: split.geminiImagePrompt))

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw GeminiSplitImageError.invalidResponse
        }

        let geminiResponse = try JSONDecoder().decode(GeminiSplitImageResponse.self, from: responseData)
        guard let base64Image = geminiResponse.candidates
            .flatMap(\.content.parts)
            .compactMap(\.inlineData?.data)
            .first,
              let imageData = Data(base64Encoded: base64Image)
        else {
            throw GeminiSplitImageError.missingImageData
        }
        return imageData
    }

    private func cachedImageData(for split: WorkoutSplit) -> Data? {
        try? Data(contentsOf: cacheURL(for: split))
    }

    private func cacheImageData(_ data: Data, for split: WorkoutSplit) throws {
        let directory = cacheDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: cacheURL(for: split), options: [.atomic])
    }

    private func cacheURL(for split: WorkoutSplit) -> URL {
        cacheDirectory().appendingPathComponent("\(split.cacheSlug).png")
    }

    private func cacheDirectory() -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return (caches ?? FileManager.default.temporaryDirectory).appendingPathComponent(cacheFolderName, isDirectory: true)
    }
}

private enum GeminiSplitImageError: Error {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case missingImageData
}

private struct GeminiSplitImageRequest: Encodable {
    let contents: [GeminiSplitImageContent]

    init(prompt: String) {
        contents = [
            GeminiSplitImageContent(parts: [
                GeminiSplitImageRequestPart(text: prompt)
            ])
        ]
    }
}

private struct GeminiSplitImageContent: Codable {
    let parts: [GeminiSplitImageRequestPart]
}

private struct GeminiSplitImageRequestPart: Codable {
    let text: String?
}

private struct GeminiSplitImageResponse: Decodable {
    let candidates: [GeminiSplitImageCandidate]
}

private struct GeminiSplitImageCandidate: Decodable {
    let content: GeminiSplitImageResponseContent
}

private struct GeminiSplitImageResponseContent: Decodable {
    let parts: [GeminiSplitImageResponsePart]
}

private struct GeminiSplitImageResponsePart: Decodable {
    let inlineData: GeminiSplitInlineData?

    private enum CodingKeys: String, CodingKey {
        case inlineData
        case inline_data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inlineData = try container.decodeIfPresent(GeminiSplitInlineData.self, forKey: .inlineData)
            ?? container.decodeIfPresent(GeminiSplitInlineData.self, forKey: .inline_data)
    }
}

private struct GeminiSplitInlineData: Decodable {
    let data: String
}

private extension WorkoutSplit {
    var cacheSlug: String {
        rawValue
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }

    var geminiImagePrompt: String {
        """
        Create one square thumbnail image for the workout split selector in a premium iOS gym app.
        Workout split: \(title).
        Meaning: \(geminiPromptDescription).
        Style: polished 3D editorial fitness illustration, realistic gym materials, clean dark charcoal background, controlled red and lime accent lighting, high contrast, crisp at 90 by 90 pixels.
        Composition: one clear central visual that explains the split, not a UI screenshot.
        Constraints: no text, no numbers, no logos, no watermark, no identifiable faces, no brand names.
        """
    }

    var geminiPromptDescription: String {
        switch self {
        case .fullBody:
            return "a balanced session covering upper body, lower body, and core in one workout"
        case .upperLower:
            return "alternating upper-body and lower-body training days"
        case .pushPullLegs:
            return "push muscles, pull muscles, and legs organized as three training focuses"
        case .broSplit:
            return "one major muscle group or body region focused each day"
        case .arnoldSplit:
            return "classic chest and back, shoulders and arms, then legs training rotation"
        case .pushPull:
            return "pushing movement patterns and pulling movement patterns split across sessions"
        case .antagonistSplit:
            return "opposing muscle groups paired together for balanced work"
        case .hybridSplit:
            return "compound strength work blended with accessory hypertrophy training"
        case .custom:
            return "a personalized split plan represented by a gym notebook and training tools"
        }
    }
}
