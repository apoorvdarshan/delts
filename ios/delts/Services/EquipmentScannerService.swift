import Foundation

struct EquipmentScanResult {
    let equipment: [Equipment]
    let confidence: Double
}

enum EquipmentScannerError: LocalizedError {
    case notImplemented

    var errorDescription: String? {
        "Equipment scanning is coming soon."
    }
}

final class EquipmentScannerService {
    func scanEquipment(fromImageData imageData: Data?) async throws -> EquipmentScanResult {
        guard imageData != nil else {
            throw EquipmentScannerError.notImplemented
        }

        // Placeholder for a future Vision or Gemini Vision equipment classifier.
        throw EquipmentScannerError.notImplemented
    }
}
