import Foundation

struct FreeExerciseDBAssetResolver {
    static func exercisesJSONURL() -> URL? {
        firstExistingURL(candidates: [
            Bundle.main.url(forResource: "exercises", withExtension: "json"),
            Bundle.main.url(forResource: "exercises", withExtension: "json", subdirectory: "FreeExerciseDB/dist"),
            Bundle.main.url(forResource: "exercises", withExtension: "json", subdirectory: "Resources/FreeExerciseDB/dist"),
            Bundle.main.resourceURL?.appendingPathComponent("FreeExerciseDB/dist/exercises.json"),
            Bundle.main.resourceURL?.appendingPathComponent("Resources/FreeExerciseDB/dist/exercises.json")
        ])
    }

    static func imageURLs(for imagePaths: [String]) -> [URL] {
        imagePaths.compactMap { imagePath in
            imageURL(for: imagePath)
        }
    }

    static func imageURLs(forExerciseName exerciseName: String?) -> [URL] {
        guard let key = exerciseName?.normalizedExerciseName else {
            return []
        }

        if let exactPaths = imagePathsByName[key] {
            return imageURLs(for: exactPaths)
        }

        return []
    }

    private static let imagePathsByName: [String: [String]] = {
        imageRecords.reduce(into: [:]) { partialResult, record in
            partialResult[record.name.normalizedExerciseName] = record.images
        }
    }()

    private static let imageRecords: [FreeExerciseDBRecord] = {
        guard
            let url = exercisesJSONURL(),
            let data = try? Data(contentsOf: url),
            let records = try? JSONDecoder().decode([FreeExerciseDBRecord].self, from: data)
        else {
            return []
        }

        return records
    }()

    private static func imageURL(for relativePath: String) -> URL? {
        let cleanPath = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let path = cleanPath as NSString
        let filename = path.deletingPathExtension
        let fileExtension = path.pathExtension.isEmpty ? nil : path.pathExtension

        return firstExistingURL(candidates: [
            Bundle.main.url(forResource: filename, withExtension: fileExtension),
            Bundle.main.url(forResource: cleanPath, withExtension: nil, subdirectory: "FreeExerciseDB/images"),
            Bundle.main.url(forResource: cleanPath, withExtension: nil, subdirectory: "Resources/FreeExerciseDB/images"),
            Bundle.main.resourceURL?.appendingPathComponent("FreeExerciseDB/images/\(cleanPath)"),
            Bundle.main.resourceURL?.appendingPathComponent("Resources/FreeExerciseDB/images/\(cleanPath)")
        ])
    }

    private static func firstExistingURL(candidates: [URL?]) -> URL? {
        candidates.compactMap { $0 }.first { FileManager.default.fileExists(atPath: $0.path) }
    }

}

private extension String {
    var normalizedExerciseName: String {
        lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
