import SwiftData
import SwiftUI
import UIKit

struct ProgressTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CompletedWorkout.date, order: .reverse) private var workouts: [CompletedWorkout]
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @AppStorage("profile_measurement_system") private var measurementSystemRaw = "metric"
    @AppStorage("apple_health_enabled") private var appleHealthEnabled = false
    @AppStorage("profile_goal_weight_kg") private var goalWeightKG = 0.0
    @AppStorage("profile_current_body_fat_is_exact") private var currentBodyFatIsExact = false
    @AppStorage("profile_goal_body_fat_is_exact") private var goalBodyFatIsExact = false
    @State private var selectedRange: ProgressRange = .month
    @State private var snapshots: [ProgressMetricSnapshot] = ProgressMetricStore.load()
    @State private var isLoggingWeight = false
    @State private var isLoggingBodyFat = false
    @State private var editingSnapshot: ProgressMetricSnapshot?
    @State private var healthSyncMessage = ""
    @StateObject private var healthKit = HealthKitProgressService()

    private var filteredSnapshots: [ProgressMetricSnapshot] {
        selectedRange.filter(snapshots).sorted { $0.date < $1.date }
    }

    private var filteredWorkouts: [CompletedWorkout] {
        selectedRange.filter(workouts)
    }

    private var filteredWeightPoints: [ProgressMetricPoint] {
        filteredSnapshots.compactMap { snapshot in
            guard let weightKg = snapshot.weightKg else { return nil }
            return ProgressMetricPoint(date: snapshot.date, value: usesImperialUnits ? weightKg * 2.2046226218 : weightKg)
        }
    }

    private var filteredBodyFatPoints: [ProgressMetricPoint] {
        filteredSnapshots.compactMap { snapshot in
            guard let bodyFat = snapshot.bodyFat else { return nil }
            return ProgressMetricPoint(date: snapshot.date, value: bodyFat)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    metricActions
                    rangePicker
                    metricGraphs
                    metricHistory
                    workoutHistory
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 122)
            }
            .deltsScreen()
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                recordCurrentSnapshot()
                if appleHealthEnabled {
                    Task { await syncHealthKit() }
                }
            }
            .onChange(of: profiles.first?.currentWeightKG) {
                recordCurrentSnapshot()
            }
            .onChange(of: profiles.first?.currentBodyFatPercentage) {
                recordCurrentSnapshot()
            }
            .sheet(isPresented: $isLoggingWeight) {
                MetricValueLogSheet(
                    title: "Log Weight",
                    valueTitle: "Weight",
                    initialValue: displayWeight(profiles.first?.currentWeightKG ?? latestWeightKg ?? 0),
                    unit: usesImperialUnits ? "lb" : "kg",
                    keyboardType: .decimalPad
                ) { value in
                    logWeight(displayValue: value)
                }
            }
            .sheet(isPresented: $isLoggingBodyFat) {
                MetricValueLogSheet(
                    title: "Log Body Fat",
                    valueTitle: "Body fat",
                    initialValue: latestBodyFat ?? profiles.first?.currentBodyFatPercentage ?? 0,
                    unit: "%",
                    keyboardType: .decimalPad
                ) { value in
                    logBodyFat(value)
                }
            }
            .sheet(item: $editingSnapshot) { snapshot in
                MetricSnapshotEditSheet(
                    snapshot: snapshot,
                    usesImperialUnits: usesImperialUnits
                ) { updated in
                    updateSnapshot(updated)
                }
            }
        }
    }

    private var metricActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                MetricActionButton(title: "Log Weight", systemImage: "scalemass.fill") {
                    isLoggingWeight = true
                }
                MetricActionButton(title: "Log Body Fat", systemImage: "percent") {
                    isLoggingBodyFat = true
                }
            }

            if appleHealthEnabled {
                Button {
                    Task { await syncHealthKit() }
                } label: {
                    Label("Sync Apple Health history", systemImage: "heart.text.square")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.deltsPanel.opacity(0.24), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
                        }
                }
                .deltsPressable()
            }

            if !healthSyncMessage.isEmpty {
                Text(healthSyncMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
            }
        }
    }

    private var rangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(ProgressRange.allCases) { range in
                    Button {
                        selectedRange = range
                    } label: {
                        Text(range.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(selectedRange == range ? Color.deltsOnAccent : Color.deltsCharcoal)
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                            .background(selectedRange == range ? Color.deltsAccent : Color.deltsPanel.opacity(0.24), in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
                            }
                    }
                    .deltsPressable()
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private var metricGraphs: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProgressMetricCard(
                title: "Body Weight",
                unit: usesImperialUnits ? "lb" : "kg",
                values: filteredWeightPoints,
                currentValue: profiles.first.map { displayWeight($0.currentWeightKG) } ?? filteredWeightPoints.last?.value,
                goalValue: effectiveGoalWeightKG.map(displayWeight),
                goalText: nil,
                averagePeriodTitle: selectedRange.title,
                averagePeriodDays: selectedRange.averagePeriodDays
            )

            ProgressMetricCard(
                title: "Body Fat",
                unit: "%",
                values: filteredBodyFatPoints,
                currentValue: currentBodyFatValue,
                goalValue: nil,
                goalText: goalBodyFatText,
                averagePeriodTitle: selectedRange.title,
                averagePeriodDays: selectedRange.averagePeriodDays
            )
        }
    }

    @ViewBuilder
    private var metricHistory: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Metric History")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)

            if filteredSnapshots.isEmpty {
                Text("No weight or body fat logs in this range.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.deltsPanel.opacity(0.24), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredSnapshots.sorted { $0.date > $1.date }) { snapshot in
                        MetricHistoryRow(
                            snapshot: snapshot,
                            weightText: snapshot.weightKg.map { formattedWeight($0) } ?? "--",
                            bodyFatText: bodyFatText(for: snapshot),
                            edit: { editingSnapshot = snapshot },
                            delete: { deleteSnapshot(snapshot) }
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var workoutHistory: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Workout History")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)

            if filteredWorkouts.isEmpty {
                Text("No completed workouts in this range.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.deltsPanel.opacity(0.24), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredWorkouts) { workout in
                        WorkoutHistoryRow(workout: workout)
                    }
                }
            }
        }
    }

    private func recordCurrentSnapshot() {
        guard let profile = profiles.first else { return }
        snapshots = ProgressMetricStore.record(
            weightKg: profile.currentWeightKG,
            bodyFat: profile.currentBodyFatPercentage,
            bodyFatIsExact: currentBodyFatIsExact,
            in: snapshots
        )
    }

    private var latestWeightKg: Double? {
        snapshots.sorted { $0.date < $1.date }.last(where: { $0.weightKg != nil })?.weightKg
    }

    private var latestBodyFat: Double? {
        snapshots.sorted { $0.date < $1.date }.last(where: { $0.bodyFat != nil })?.bodyFat
    }

    private var currentBodyFatValue: Double? {
        profiles.first?.currentBodyFatPercentage ?? filteredBodyFatPoints.last?.value
    }

    private var goalBodyFatText: String? {
        guard let profile = profiles.first else { return nil }
        if goalBodyFatIsExact {
            return String(format: "%.1f%%", profile.desiredBodyFatPercentage)
        }
        return progressBodyFatRangeTitle(for: profile.desiredBodyFatPercentage)
    }

    private func bodyFatText(for snapshot: ProgressMetricSnapshot) -> String {
        guard let bodyFat = snapshot.bodyFat else { return "--" }
        return String(format: "%.1f%%", bodyFat)
    }

    private var effectiveGoalWeightKG: Double? {
        if goalWeightKG > 0 {
            return goalWeightKG
        }
        return profiles.first?.currentWeightKG ?? latestWeightKg
    }

    private func displayWeight(_ kg: Double) -> Double {
        usesImperialUnits ? kg * 2.2046226218 : kg
    }

    private func weightKg(fromDisplayValue value: Double) -> Double {
        usesImperialUnits ? value / 2.2046226218 : value
    }

    private func formattedWeight(_ kg: Double) -> String {
        String(format: "%.1f %@", displayWeight(kg), usesImperialUnits ? "lb" : "kg")
    }

    private func progressBodyFatRangeTitle(for value: Double) -> String {
        let roundedValue = value.rounded()
        switch roundedValue {
        case ...9:
            return "6-9%"
        case 10...13:
            return "10-13%"
        case 14...17:
            return "14-17%"
        case 18...22:
            return "18-22%"
        case 23...27:
            return "23-27%"
        case 28...32:
            return "28-32%"
        default:
            return "33%+"
        }
    }

    private func logWeight(displayValue: Double) {
        let weightKg = weightKg(fromDisplayValue: displayValue)
        let date = Date()
        snapshots = ProgressMetricStore.record(weightKg: weightKg, bodyFat: nil, date: date, in: snapshots)
        let snapshotID = snapshotID(for: date)
        updateProfile(weightKg: weightKg, bodyFat: nil)
        if appleHealthEnabled {
            Task {
                try? await healthKit.saveWeight(kg: weightKg, date: date, snapshotID: snapshotID)
            }
        }
    }

    private func logBodyFat(_ bodyFat: Double) {
        let date = Date()
        snapshots = ProgressMetricStore.record(weightKg: nil, bodyFat: bodyFat, bodyFatIsExact: true, date: date, in: snapshots)
        let snapshotID = snapshotID(for: date)
        updateProfile(weightKg: nil, bodyFat: bodyFat)
        if appleHealthEnabled {
            Task {
                try? await healthKit.saveBodyFat(percent: bodyFat, date: date, snapshotID: snapshotID)
            }
        }
    }

    private func updateSnapshot(_ updated: ProgressMetricSnapshot) {
        let previous = snapshots.first { $0.id == updated.id } ?? updated
        snapshots = ProgressMetricStore.update(updated, in: snapshots)
        if isLatestSnapshot(updated) {
            updateProfile(weightKg: updated.weightKg, bodyFat: updated.bodyFat)
        }
        if appleHealthEnabled {
            Task {
                _ = try? await healthKit.deleteSnapshot(previous)
                if let weightKg = updated.weightKg {
                    try? await healthKit.saveWeight(kg: weightKg, date: updated.date, snapshotID: updated.id)
                }
                if let bodyFat = updated.bodyFat {
                    try? await healthKit.saveBodyFat(percent: bodyFat, date: updated.date, snapshotID: updated.id)
                }
            }
        }
    }

    private func deleteSnapshot(_ snapshot: ProgressMetricSnapshot) {
        snapshots = ProgressMetricStore.delete(snapshot.id, from: snapshots)
        guard appleHealthEnabled else { return }
        Task {
            do {
                let count = try await healthKit.deleteSnapshot(snapshot)
                healthSyncMessage = count > 0 ? "Deleted from Apple Health." : "Deleted locally. No Apple Health sample matched."
            } catch {
                healthSyncMessage = error.localizedDescription
            }
        }
    }

    private func updateProfile(weightKg: Double?, bodyFat: Double?) {
        guard let profile = profiles.first else { return }
        if let weightKg {
            profile.currentWeightKG = weightKg
        }
        if let bodyFat {
            profile.currentBodyFatPercentage = bodyFat
            currentBodyFatIsExact = true
        }
        profile.updatedAt = Date()
        try? modelContext.save()
    }

    private func isLatestSnapshot(_ snapshot: ProgressMetricSnapshot) -> Bool {
        guard let latest = snapshots.max(by: { $0.date < $1.date }) else { return true }
        return latest.id == snapshot.id || snapshot.date >= latest.date
    }

    private func snapshotID(for date: Date) -> UUID? {
        snapshots.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.id
    }

    private func syncHealthKit() async {
        do {
            try await healthKit.requestAccess()
            let imported = try await healthKit.importAllSnapshots()
            snapshots = ProgressMetricStore.merge(imported, into: snapshots)
            if let latestImportedBodyFat = snapshots.sorted(by: { $0.date < $1.date }).last(where: { $0.bodyFat != nil && $0.bodyFatIsExact == true })?.bodyFat {
                updateProfile(weightKg: nil, bodyFat: latestImportedBodyFat)
            }
            healthSyncMessage = imported.isEmpty ? "Apple Health connected. No previous weight/body fat samples found." : "Imported \(imported.count) Apple Health metric day\(imported.count == 1 ? "" : "s")."
        } catch {
            healthSyncMessage = error.localizedDescription
        }
    }

    private var usesImperialUnits: Bool {
        measurementSystemRaw == "imperial"
    }
}

private enum ProgressRange: String, CaseIterable, Identifiable {
    case week
    case month
    case threeMonths
    case sixMonths
    case year
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .year: return "1Y"
        case .all: return "All"
        }
    }

    private var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .week: return calendar.date(byAdding: .day, value: -7, to: Date())
        case .month: return calendar.date(byAdding: .month, value: -1, to: Date())
        case .threeMonths: return calendar.date(byAdding: .month, value: -3, to: Date())
        case .sixMonths: return calendar.date(byAdding: .month, value: -6, to: Date())
        case .year: return calendar.date(byAdding: .year, value: -1, to: Date())
        case .all: return nil
        }
    }

    func filter(_ snapshots: [ProgressMetricSnapshot]) -> [ProgressMetricSnapshot] {
        guard let startDate else { return snapshots }
        return snapshots.filter { $0.date >= startDate }
    }

    func filter(_ workouts: [CompletedWorkout]) -> [CompletedWorkout] {
        guard let startDate else { return workouts }
        return workouts.filter { $0.date >= startDate }
    }

    var averagePeriodDays: Double? {
        switch self {
        case .week: return 7
        case .month: return 31
        case .threeMonths: return 93
        case .sixMonths: return 186
        case .year: return 366
        case .all: return nil
        }
    }
}

struct ProgressMetricSnapshot: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var weightKg: Double?
    var bodyFat: Double?
    var bodyFatIsExact: Bool?
}

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

private struct ProgressMetricPoint: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let value: Double
}

private struct MetricActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.deltsPanel.opacity(0.28), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Color.deltsHairline.opacity(0.32), lineWidth: 0.5)
                }
        }
        .deltsPressable()
    }
}

private struct ProgressMetricCard: View {
    let title: String
    let unit: String
    let values: [ProgressMetricPoint]
    let currentValue: Double?
    let goalValue: Double?
    let goalText: String?
    let averagePeriodTitle: String
    let averagePeriodDays: Double?

    private var latestValue: Double? {
        values.last?.value
    }

    private var averageChangeValue: Double? {
        guard let first = values.first,
              let last = values.last,
              first.date != last.date
        else { return nil }
        let elapsedDays = max(last.date.timeIntervalSince(first.date) / 86_400, 1)
        let periodDays = averagePeriodDays ?? elapsedDays
        return (last.value - first.value) / elapsedDays * periodDays
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                    Text(values.count <= 1 ? "Current profile value" : "\(values.count) entries")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                }

                Spacer()

                if let latestValue {
                    Text(formatted(latestValue))
                        .font(.title3.monospacedDigit().weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                }
            }

            HStack(spacing: 8) {
                MetricStatTile(title: "Current", value: currentValue.map(formatted) ?? "--")
                MetricStatTile(title: "Goal", value: goalText ?? goalValue.map(formatted) ?? "--")
                MetricStatTile(title: "Avg Δ / \(averagePeriodTitle)", value: averageChangeValue.map(formattedSigned) ?? "--")
            }

            MetricLineGraph(points: values.map(\.value))
                .frame(height: 150)
        }
        .padding(16)
        .background(Color.deltsPanel.opacity(0.22), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
        }
    }

    private func formatted(_ value: Double) -> String {
        if unit == "%" {
            return String(format: "%.1f%%", value)
        }
        return String(format: "%.1f %@", value, unit)
    }

    private func formattedSigned(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        if unit == "%" {
            return "\(sign)\(String(format: "%.1f%%", value))"
        }
        return "\(sign)\(String(format: "%.1f %@", value, unit))"
    }
}

private struct MetricStatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(value)
                .font(.caption.monospacedDigit().weight(.heavy))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.64)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .frame(height: 48)
        .background(Color.deltsPanel.opacity(0.20), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MetricLineGraph: View {
    let points: [Double]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let minValue = points.min() ?? 0
            let maxValue = points.max() ?? 1
            let spread = max(maxValue - minValue, 1)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.deltsCard.opacity(0.42))

                Path { path in
                    guard !points.isEmpty else { return }
                    for index in points.indices {
                        let x = points.count == 1 ? size.width / 2 : CGFloat(index) / CGFloat(points.count - 1) * size.width
                        let y = size.height - CGFloat((points[index] - minValue) / spread) * (size.height - 18) - 9
                        if index == points.startIndex {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.deltsAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                ForEach(points.indices, id: \.self) { index in
                    let x = points.count == 1 ? size.width / 2 : CGFloat(index) / CGFloat(points.count - 1) * size.width
                    let y = size.height - CGFloat((points[index] - minValue) / spread) * (size.height - 18) - 9
                    Circle()
                        .fill(Color.deltsSecondaryAccent)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

private struct MetricHistoryRow: View {
    let snapshot: ProgressMetricSnapshot
    let weightText: String
    let bodyFatText: String
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(snapshot.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)

                HStack(spacing: 8) {
                    MetricHistoryPill(title: "Weight", value: weightText)
                    MetricHistoryPill(title: "Body fat", value: bodyFatText)
                }
            }

            Spacer(minLength: 4)

            Button(action: edit) {
                Image(systemName: "pencil")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
                    .frame(width: 34, height: 34)
            }
            .deltsPressable()

            Button(action: delete) {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsInferno)
                    .frame(width: 34, height: 34)
            }
            .deltsPressable()
        }
        .padding(14)
        .background(Color.deltsPanel.opacity(0.20), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
        }
    }
}

private struct MetricHistoryPill: View {
    let title: String
    let value: String

    var body: some View {
        Text("\(title) \(value)")
            .font(.caption2.monospacedDigit().weight(.bold))
            .foregroundStyle(Color.deltsSecondaryAccent)
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(Color.deltsSecondaryAccent.opacity(0.10), in: Capsule())
    }
}

private struct MetricValueLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let valueTitle: String
    let unit: String
    let keyboardType: UIKeyboardType
    let save: (Double) -> Void
    @State private var rawValue: String

    init(
        title: String,
        valueTitle: String,
        initialValue: Double,
        unit: String,
        keyboardType: UIKeyboardType,
        save: @escaping (Double) -> Void
    ) {
        self.title = title
        self.valueTitle = valueTitle
        self.unit = unit
        self.keyboardType = keyboardType
        self.save = save
        _rawValue = State(initialValue: initialValue > 0 ? String(format: "%.1f", initialValue) : "")
    }

    private var parsedValue: Double? {
        Double(rawValue.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                TextField(valueTitle, text: $rawValue)
                    .keyboardType(keyboardType)
                    .textFieldStyle(.plain)
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .padding(.horizontal, 14)
                    .frame(height: 56)
                    .background(Color.deltsPanel.opacity(0.30), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(alignment: .trailing) {
                        Text(unit)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.deltsMutedText)
                            .padding(.trailing, 14)
                    }

                PrimaryButton(title: "Save", systemImage: "checkmark") {
                    guard let parsedValue else { return }
                    save(parsedValue)
                    dismiss()
                }
                .disabled(parsedValue == nil)

                Spacer()
            }
            .padding(20)
            .deltsScreen()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct MetricSnapshotEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let snapshot: ProgressMetricSnapshot
    let usesImperialUnits: Bool
    let save: (ProgressMetricSnapshot) -> Void
    @State private var weightRaw: String
    @State private var bodyFatRaw: String

    init(snapshot: ProgressMetricSnapshot, usesImperialUnits: Bool, save: @escaping (ProgressMetricSnapshot) -> Void) {
        self.snapshot = snapshot
        self.usesImperialUnits = usesImperialUnits
        self.save = save
        let weightDisplay = snapshot.weightKg.map { usesImperialUnits ? $0 * 2.2046226218 : $0 }
        _weightRaw = State(initialValue: weightDisplay.map { String(format: "%.1f", $0) } ?? "")
        _bodyFatRaw = State(initialValue: snapshot.bodyFat.map { String(format: "%.1f", $0) } ?? "")
    }

    private var parsedWeightKg: Double? {
        guard !weightRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let value = Double(weightRaw.replacingOccurrences(of: ",", with: "."))
        else { return nil }
        return usesImperialUnits ? value / 2.2046226218 : value
    }

    private var parsedBodyFat: Double? {
        guard !bodyFatRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return Double(bodyFatRaw.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                MetricEditField(title: "Weight", unit: usesImperialUnits ? "lb" : "kg", text: $weightRaw)
                MetricEditField(title: "Body fat", unit: "%", text: $bodyFatRaw)

                PrimaryButton(title: "Save Changes", systemImage: "checkmark") {
                    var updated = snapshot
                    updated.weightKg = parsedWeightKg
                    updated.bodyFat = parsedBodyFat
                    updated.bodyFatIsExact = parsedBodyFat == nil ? nil : true
                    save(updated)
                    dismiss()
                }

                Spacer()
            }
            .padding(20)
            .deltsScreen()
            .navigationTitle("Edit Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct MetricEditField: View {
    let title: String
    let unit: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.heavy))
                .textCase(.uppercase)
                .foregroundStyle(Color.deltsMutedText)
            TextField(title, text: $text)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Color.deltsPanel.opacity(0.30), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .trailing) {
                    Text(unit)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText)
                        .padding(.trailing, 14)
                }
        }
    }
}

private struct WorkoutHistoryRow: View {
    let workout: CompletedWorkout

    private var setCount: Int {
        workout.exerciseLogs.reduce(0) { total, log in
            total + log.sets.filter(\.completed).count
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(workout.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(2)

                Spacer()

                Text("\(workout.durationMinutes)m")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
            }

            Text("\(workout.date.formatted(date: .abbreviated, time: .shortened)) - \(setCount) set\(setCount == 1 ? "" : "s")")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)

            let stamps = workout.exerciseLogs
                .flatMap(\.sets)
                .compactMap(\.elapsedSeconds)
                .prefix(4)

            if !stamps.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(stamps), id: \.self) { seconds in
                        Text(ActiveWorkoutViewModel.elapsedDisplay(seconds))
                            .font(.caption2.monospacedDigit().weight(.bold))
                            .foregroundStyle(Color.deltsSecondaryAccent)
                            .padding(.horizontal, 8)
                            .frame(height: 26)
                            .background(Color.deltsSecondaryAccent.opacity(0.10), in: Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(Color.deltsPanel.opacity(0.20), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
        }
    }
}
