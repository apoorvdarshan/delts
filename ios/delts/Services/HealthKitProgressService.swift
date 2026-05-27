import Combine
import Foundation
import HealthKit

@MainActor
final class HealthKitProgressService: ObservableObject {
    @Published var statusMessage = ""

    private let store = HKHealthStore()

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

    func saveWeight(kg: Double, date: Date = Date()) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitProgressError.unavailable
        }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        try await save(quantity: quantity, type: type, date: date)
    }

    func saveBodyFat(percent: Double, date: Date = Date()) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else {
            throw HealthKitProgressError.unavailable
        }
        let quantity = HKQuantity(unit: .percent(), doubleValue: percent / 100)
        try await save(quantity: quantity, type: type, date: date)
    }

    private func quantitySamples(for type: HKQuantityType) async throws -> [HKQuantitySample] {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
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

    private func save(quantity: HKQuantity, type: HKQuantityType, date: Date) async throws {
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
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
