import Combine
import Foundation
import HealthKit

@MainActor
final class HealthKitProgressService: ObservableObject {
    @Published var statusMessage = ""

    private let store = HKHealthStore()
    private let snapshotMetadataKey = "delts.metric.snapshot.id"

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAccess() async throws {
        guard isAvailable,
              let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass),
              let bodyFat = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)
        else {
            throw HealthKitProgressError.unavailable
        }

        let types: Set<HKSampleType> = [bodyMass, bodyFat]
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.requestAuthorization(toShare: types, read: types) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitProgressError.denied)
                }
            }
        }
    }

    func importAllSnapshots() async throws -> [ProgressMetricSnapshot] {
        guard isAvailable,
              let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass),
              let bodyFat = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)
        else {
            throw HealthKitProgressError.unavailable
        }

        async let weightSamples = quantitySamples(for: bodyMass)
        async let bodyFatSamples = quantitySamples(for: bodyFat)
        let (weights, bodyFats) = try await (weightSamples, bodyFatSamples)

        var snapshotsByDay: [Date: ProgressMetricSnapshot] = [:]
        let calendar = Calendar.current

        for sample in weights {
            let day = calendar.startOfDay(for: sample.startDate)
            var snapshot = snapshotsByDay[day] ?? ProgressMetricSnapshot(date: sample.startDate, weightKg: nil, bodyFat: nil)
            if sample.startDate >= snapshot.date || snapshot.weightKg == nil {
                snapshot.date = sample.startDate
                snapshot.weightKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            }
            snapshotsByDay[day] = snapshot
        }

        for sample in bodyFats {
            let day = calendar.startOfDay(for: sample.startDate)
            var snapshot = snapshotsByDay[day] ?? ProgressMetricSnapshot(date: sample.startDate, weightKg: nil, bodyFat: nil)
            if sample.startDate >= snapshot.date || snapshot.bodyFat == nil {
                snapshot.date = sample.startDate
                snapshot.bodyFat = sample.quantity.doubleValue(for: .percent()) * 100
            }
            snapshotsByDay[day] = snapshot
        }

        return snapshotsByDay.values.sorted { $0.date < $1.date }
    }

    func saveWeight(kg: Double, date: Date = Date(), snapshotID: UUID? = nil) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitProgressError.unavailable
        }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        try await save(quantity: quantity, type: type, date: date, snapshotID: snapshotID)
    }

    func saveBodyFat(percent: Double, date: Date = Date(), snapshotID: UUID? = nil) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else {
            throw HealthKitProgressError.unavailable
        }
        let quantity = HKQuantity(unit: .percent(), doubleValue: percent / 100)
        try await save(quantity: quantity, type: type, date: date, snapshotID: snapshotID)
    }

    func deleteSnapshot(_ snapshot: ProgressMetricSnapshot) async throws -> Int {
        guard isAvailable else {
            throw HealthKitProgressError.unavailable
        }

        var samples: [HKQuantitySample] = []
        if let weightKg = snapshot.weightKg,
           let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
            let matches = try await samplesForDeletion(type: type, snapshotID: snapshot.id, date: snapshot.date, quantity: quantity)
            samples.append(contentsOf: matches)
        }

        if let bodyFat = snapshot.bodyFat,
           let type = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) {
            let quantity = HKQuantity(unit: .percent(), doubleValue: bodyFat / 100)
            let matches = try await samplesForDeletion(type: type, snapshotID: snapshot.id, date: snapshot.date, quantity: quantity)
            samples.append(contentsOf: matches)
        }

        let uniqueSamples = Dictionary(grouping: samples, by: \.uuid).compactMap { $0.value.first }
        guard !uniqueSamples.isEmpty else { return 0 }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.delete(uniqueSamples) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitProgressError.denied)
                }
            }
        }
        return uniqueSamples.count
    }

    private func quantitySamples(for type: HKQuantityType, predicate: NSPredicate? = nil) async throws -> [HKQuantitySample] {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                }
            }
            store.execute(query)
        }
    }

    private func samplesForDeletion(type: HKQuantityType, snapshotID: UUID, date: Date, quantity: HKQuantity) async throws -> [HKQuantitySample] {
        let metadataPredicate = HKQuery.predicateForObjects(withMetadataKey: snapshotMetadataKey, allowedValues: [snapshotID.uuidString])
        let metadataMatches = try await quantitySamples(for: type, predicate: metadataPredicate)
            .filter(isCurrentAppSample)
        if !metadataMatches.isEmpty {
            return metadataMatches
        }

        let start = date.addingTimeInterval(-10)
        let end = date.addingTimeInterval(10)
        let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate])
        let targetValue = quantity.doubleValue(for: unit(for: type))
        return try await quantitySamples(for: type, predicate: datePredicate)
            .filter(isCurrentAppSample)
            .filter { sample in
                abs(sample.quantity.doubleValue(for: unit(for: type)) - targetValue) < 0.0001
            }
    }

    private func save(quantity: HKQuantity, type: HKQuantityType, date: Date, snapshotID: UUID?) async throws {
        var metadata: [String: Any] = [:]
        if let snapshotID {
            metadata[HKMetadataKeyExternalUUID] = snapshotID.uuidString
            metadata[snapshotMetadataKey] = snapshotID.uuidString
        }

        let sample = HKQuantitySample(
            type: type,
            quantity: quantity,
            start: date,
            end: date,
            metadata: metadata.isEmpty ? nil : metadata
        )
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.save(sample) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitProgressError.denied)
                }
            }
        }
    }

    private func isCurrentAppSample(_ sample: HKQuantitySample) -> Bool {
        sample.sourceRevision.source.bundleIdentifier == Bundle.main.bundleIdentifier
    }

    private func unit(for type: HKQuantityType) -> HKUnit {
        type.identifier == HKQuantityTypeIdentifier.bodyFatPercentage.rawValue
            ? .percent()
            : .gramUnit(with: .kilo)
    }
}

enum HealthKitProgressError: LocalizedError {
    case unavailable
    case denied

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Apple Health is not available on this device."
        case .denied:
            return "Apple Health permission was not granted."
        }
    }
}
