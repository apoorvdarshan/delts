import Foundation
import SwiftData

/// Persisted Coach chat message. The conversation survives app restarts and is
/// only cleared when the user taps Reset.
@Model
final class CoachMessageRecord {
    @Attribute(.unique) var id: UUID
    var roleRaw: String
    var text: String
    var isError: Bool
    var createdAt: Date
    @Attribute(.externalStorage) var imageData: Data?

    init(
        id: UUID = UUID(),
        roleRaw: String,
        text: String,
        isError: Bool = false,
        createdAt: Date = Date(),
        imageData: Data? = nil
    ) {
        self.id = id
        self.roleRaw = roleRaw
        self.text = text
        self.isError = isError
        self.createdAt = createdAt
        self.imageData = imageData
    }
}
