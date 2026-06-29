import Foundation

/// A single dated body-metric reading (weight / body fat), persisted locally and
/// optionally imported from Apple Health. Used by the profile's Apple Health sync.
struct ProgressMetricSnapshot: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var weightKg: Double?
    var bodyFat: Double?
    var bodyFatIsExact: Bool?
}

/// UserDefaults-backed store for body-metric snapshots.
enum ProgressMetricStore {
    private static let key = "delts.progressMetrics.v1"

    static func load() -> [ProgressMetricSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snapshots = try? JSONDecoder().decode([ProgressMetricSnapshot].self, from: data)
        else {
            return []
        }
        return snapshots.sorted { $0.date < $1.date }
    }

    static func record(
        weightKg: Double?,
        bodyFat: Double?,
        bodyFatIsExact: Bool? = nil,
        date: Date = Date(),
        in current: [ProgressMetricSnapshot]
    ) -> [ProgressMetricSnapshot] {
        var snapshots = current
        upsert(
            ProgressMetricSnapshot(
                date: date,
                weightKg: weightKg,
                bodyFat: bodyFat,
                bodyFatIsExact: bodyFat == nil ? nil : (bodyFatIsExact ?? true)
            ),
            into: &snapshots
        )
        save(snapshots)
        return snapshots.sorted { $0.date < $1.date }
    }

    static func merge(_ imported: [ProgressMetricSnapshot], into current: [ProgressMetricSnapshot]) -> [ProgressMetricSnapshot] {
        var snapshots = current
        for snapshot in imported {
            upsert(snapshot, into: &snapshots)
        }
        save(snapshots)
        return snapshots.sorted { $0.date < $1.date }
    }

    static func update(_ updated: ProgressMetricSnapshot, in current: [ProgressMetricSnapshot]) -> [ProgressMetricSnapshot] {
        var snapshots = current
        if let index = snapshots.firstIndex(where: { $0.id == updated.id }) {
            snapshots[index] = updated
        } else {
            upsert(updated, into: &snapshots)
        }
        save(snapshots)
        return snapshots.sorted { $0.date < $1.date }
    }

    static func delete(_ id: UUID, from current: [ProgressMetricSnapshot]) -> [ProgressMetricSnapshot] {
        let snapshots = current.filter { $0.id != id }
        save(snapshots)
        return snapshots.sorted { $0.date < $1.date }
    }

    static func save(_ snapshots: [ProgressMetricSnapshot]) {
        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func upsert(_ snapshot: ProgressMetricSnapshot, into snapshots: inout [ProgressMetricSnapshot]) {
        let calendar = Calendar.current
        if let index = snapshots.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: snapshot.date) }) {
            snapshots[index].date = max(snapshots[index].date, snapshot.date)
            if let weightKg = snapshot.weightKg {
                snapshots[index].weightKg = weightKg
            }
            if let bodyFat = snapshot.bodyFat {
                snapshots[index].bodyFat = bodyFat
                snapshots[index].bodyFatIsExact = snapshot.bodyFatIsExact ?? true
            }
        } else if snapshot.weightKg != nil || snapshot.bodyFat != nil {
            snapshots.append(snapshot)
        }
    }
}
