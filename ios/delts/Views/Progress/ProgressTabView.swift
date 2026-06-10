import SwiftData
import SwiftUI
import UIKit

struct ProgressTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \CompletedWorkout.date, order: .reverse) private var completedWorkouts: [CompletedWorkout]
    @AppStorage("profile_weight_measurement_system") private var measurementSystemRaw = "metric"
    @AppStorage("apple_health_enabled") private var appleHealthEnabled = false
    @AppStorage("profile_goal_weight_kg") private var goalWeightKG = 0.0
    @AppStorage("profile_current_body_fat_is_exact") private var currentBodyFatIsExact = false
    @AppStorage("profile_goal_body_fat_is_exact") private var goalBodyFatIsExact = false
    @AppStorage("progress_selected_metric") private var selectedMetricRaw = ProgressMetricKind.weight.rawValue
    @State private var selectedRange: ProgressRange = .month
    @State private var snapshots: [ProgressMetricSnapshot] = ProgressMetricStore.load()
    @State private var isLoggingWeight = false
    @State private var isLoggingBodyFat = false
    @State private var isShowingBodyLogs = false
    @StateObject private var healthKit = HealthKitProgressService()
    @ObservedObject private var burnEstimator = BurnEstimator.shared

    private var filteredSnapshots: [ProgressMetricSnapshot] {
        selectedRange.filter(snapshots).sorted { $0.date < $1.date }
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
                    metricPicker
                    if selectedMetric == .history {
                        workoutHistorySection
                    } else {
                        rangePicker
                        selectedMetricGraph
                        bodyLogButton
                    }
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
                ProgressMassWheelSheet(
                    title: "Log Weight",
                    initialKilograms: profiles.first?.currentWeightKG ?? latestWeightKg ?? 0,
                    initialSystem: ProgressMeasurementSystem(storedValue: measurementSystemRaw),
                    metricRange: 30...250,
                    imperialRange: 66...551
                ) { kilograms, system in
                    measurementSystemRaw = system.rawValue
                    logWeight(kg: kilograms)
                }
            }
            .sheet(isPresented: $isLoggingBodyFat) {
                ProgressBodyFatRangeSheet(
                    title: "Log Body Fat",
                    initialValue: latestBodyFat ?? profiles.first?.currentBodyFatPercentage ?? 0,
                    initialIsExact: currentBodyFatIsExact,
                    sex: profiles.first?.gender ?? "Male"
                ) { value, isExact in
                    logBodyFat(value, isExact: isExact)
                }
            }
            .sheet(isPresented: $isShowingBodyLogs) {
                BodyLogSheet(
                    snapshots: filteredSnapshots.sorted { $0.date > $1.date },
                    usesImperialUnits: usesImperialUnits,
                    weightText: formattedWeight,
                    bodyFatText: bodyFatText(for:),
                    update: updateSnapshot,
                    delete: deleteSnapshot
                )
            }
        }
    }

    private var metricPicker: some View {
        Picker("Progress metric", selection: selectedMetricBinding) {
            ForEach(ProgressMetricKind.allCases) { metric in
                Text(metric.title).tag(metric)
            }
        }
        .pickerStyle(.segmented)
        .tint(Color.deltsAccent)
    }

    private var selectedMetric: ProgressMetricKind {
        ProgressMetricKind(storedValue: selectedMetricRaw)
    }

    private var selectedMetricBinding: Binding<ProgressMetricKind> {
        Binding {
            selectedMetric
        } set: { newValue in
            selectedMetricRaw = newValue.rawValue
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 6) {
            ForEach(ProgressRange.allCases) { range in
                Button {
                    selectedRange = range
                } label: {
                    Text(range.title)
                        .font(.footnote.weight(.heavy))
                        .foregroundStyle(selectedRange == range ? Color.deltsOnAccent : Color.deltsCharcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(selectedRange == range ? Color.deltsAccent : Color.deltsPanel.opacity(0.24), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
                        }
                }
                .buttonStyle(.plain)
                .deltsPressable()
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var selectedMetricGraph: some View {
        switch selectedMetric {
        case .weight:
            weightMetricCard
        case .bodyFat:
            bodyFatMetricCard
        case .history:
            EmptyView()
        }
    }

    @ViewBuilder
    private var workoutHistorySection: some View {
        Group {
            if completedWorkouts.isEmpty {
                ProgressHistoryEmptyCard()
            } else {
                VStack(spacing: 10) {
                    ForEach(completedWorkouts) { workout in
                        WorkoutHistoryCard(
                            workout: workout,
                            isEstimating: burnEstimator.isEstimating(workout.id),
                            onDelete: { deleteCompletedWorkout(workout) }
                        )
                    }
                }
            }
        }
        .onAppear { healMissingBurns() }
    }

    /// Compute calories for recently completed workouts that don't have one yet
    /// (e.g. an on-stop estimate that failed or predates the feature). Capped so a
    /// long history doesn't fire a burst of requests.
    private func healMissingBurns() {
        let missing = completedWorkouts.filter { $0.caloriesBurned == nil }.prefix(8)
        guard !missing.isEmpty else { return }

        let profile = profiles.first
        let bio = CalorieEstimateService.Bio(
            gender: profile?.gender ?? "Unknown",
            age: profile?.age ?? 0,
            heightCM: profile?.heightCM ?? 0,
            weightKG: profile?.currentWeightKG ?? 0,
            bodyFatPercentage: profile?.currentBodyFatPercentage ?? 0,
            experience: profile?.experienceLevel.title ?? "Intermediate"
        )

        for workout in missing {
            burnEstimator.estimateIfNeeded(
                workout: workout,
                bio: bio,
                modelContext: modelContext,
                appleHealthEnabled: appleHealthEnabled,
                healthKit: healthKit
            )
        }
    }

    private func deleteCompletedWorkout(_ workout: CompletedWorkout) {
        let id = workout.id
        modelContext.delete(workout)
        try? modelContext.save()
        if appleHealthEnabled {
            Task { try? await healthKit.deleteWorkout(id: id) }
        }
    }

    private var weightMetricCard: some View {
        ProgressMetricCard(
            title: "Weight",
            unit: usesImperialUnits ? "lb" : "kg",
            values: filteredWeightPoints,
            range: selectedRange,
            currentValue: profiles.first.map { displayWeight($0.currentWeightKG) } ?? filteredWeightPoints.last?.value,
            goalValue: effectiveGoalWeightKG.map(displayWeight),
            goalText: nil,
            actionTitle: "Log Weight",
            actionSystemImage: "plus.circle.fill",
            onLog: {
                isLoggingWeight = true
            }
        )
    }

    private var bodyFatMetricCard: some View {
        ProgressMetricCard(
            title: "Body Fat",
            unit: "%",
            values: filteredBodyFatPoints,
            range: selectedRange,
            currentValue: currentBodyFatValue,
            goalValue: nil,
            goalText: goalBodyFatText,
            actionTitle: "Log Body Fat",
            actionSystemImage: "plus.circle.fill",
            onLog: {
                isLoggingBodyFat = true
            }
        )
    }

    private var bodyLogButton: some View {
        Button {
            isShowingBodyLogs = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color.deltsAccent)
                    .frame(width: 38, height: 38)
                    .background(Color.deltsAccent.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Body Logs")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                    Text(filteredSnapshots.isEmpty ? "No logs in \(selectedRange.title.lowercased())" : "\(filteredSnapshots.count) log\(filteredSnapshots.count == 1 ? "" : "s") in \(selectedRange.title.lowercased())")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 10)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.heavy))
                    .foregroundStyle(Color.deltsMutedText)
            }
            .padding(14)
            .background(Color.deltsPanel.opacity(0.22), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .deltsPressable()
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
        logWeight(kg: weightKg(fromDisplayValue: displayValue))
    }

    private func logWeight(kg weightKg: Double) {
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

    private func logBodyFat(_ bodyFat: Double, isExact: Bool = true) {
        let date = Date()
        snapshots = ProgressMetricStore.record(weightKg: nil, bodyFat: bodyFat, bodyFatIsExact: isExact, date: date, in: snapshots)
        let snapshotID = snapshotID(for: date)
        updateProfile(weightKg: nil, bodyFat: bodyFat, bodyFatIsExact: isExact)
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
            updateProfile(weightKg: updated.weightKg, bodyFat: updated.bodyFat, bodyFatIsExact: updated.bodyFatIsExact)
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
            _ = try? await healthKit.deleteSnapshot(snapshot)
        }
    }

    private func updateProfile(weightKg: Double?, bodyFat: Double?, bodyFatIsExact: Bool? = nil) {
        guard let profile = profiles.first else { return }
        if let weightKg {
            profile.currentWeightKG = weightKg
        }
        if let bodyFat {
            profile.currentBodyFatPercentage = bodyFat
            currentBodyFatIsExact = bodyFatIsExact ?? true
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
                updateProfile(weightKg: nil, bodyFat: latestImportedBodyFat, bodyFatIsExact: true)
            }
        } catch {
            return
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

    var graphPointLimit: Int? {
        switch self {
        case .week:
            return nil
        case .month:
            return 14
        case .threeMonths:
            return 16
        case .sixMonths:
            return 18
        case .year:
            return 20
        case .all:
            return 22
        }
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

private enum ProgressMetricKind: String, CaseIterable, Identifiable {
    case weight
    case bodyFat
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weight:
            return "Weight"
        case .bodyFat:
            return "Body Fat"
        case .history:
            return "History"
        }
    }

    init(storedValue: String) {
        self = ProgressMetricKind(rawValue: storedValue) ?? .weight
    }
}

private struct WorkoutHistoryCard: View {
    let workout: CompletedWorkout
    var isEstimating: Bool = false
    let onDelete: () -> Void

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d · h:mm a"
        return formatter.string(from: workout.date)
    }

    private var burnText: String {
        if let kcal = workout.caloriesBurned { return "\(kcal) kcal" }
        return "-- kcal"
    }

    private var movesText: String {
        let count = workout.exerciseLogs.count
        return "\(count) \(count == 1 ? "move" : "moves")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(workout.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                Text(dateText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)

                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.deltsMutedText)
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Workout options")
            }

            HStack(spacing: 14) {
                InlineStat(icon: "clock.fill", text: "\(workout.durationMinutes) min")
                InlineStat(
                    icon: "flame.fill",
                    text: burnText,
                    tint: (workout.caloriesBurned != nil || isEstimating) ? .deltsAccent : .deltsMutedText,
                    isLoading: isEstimating
                )
                InlineStat(icon: "dumbbell.fill", text: movesText)
            }

            if !workout.exerciseLogs.isEmpty {
                Rectangle()
                    .fill(Color.deltsHairline.opacity(0.22))
                    .frame(height: 0.5)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(workout.exerciseLogs) { exercise in
                        HistoryExerciseRow(exercise: exercise)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.deltsPanel.opacity(0.22), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
        }
    }
}

private struct InlineStat: View {
    let icon: String
    let text: String
    var tint: Color = .deltsAccent
    var isLoading: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
            if isLoading {
                ProgressView()
                    .controlSize(.mini)
                    .tint(tint)
                Text("kcal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
            } else {
                Text(text)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

private struct HistoryExerciseRow: View {
    let exercise: CompletedExerciseLog

    private var contextText: String {
        [exercise.targetMuscle, exercise.equipment]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                if !contextText.isEmpty {
                    Text(contextText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                        .lineLimit(1)
                }
            }

            ForEach(exercise.sets) { set in
                HStack(spacing: 8) {
                    Text("Set \(set.setNumber)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText)
                        .frame(width: 42, alignment: .leading)

                    Text(setSummary(set))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsCharcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 0)

                    Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(set.completed ? Color.deltsAccent : Color.deltsMutedText.opacity(0.5))
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.deltsPanel.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func setSummary(_ set: CompletedSetLog) -> String {
        var parts: [String] = []
        let reps = set.reps.trimmingCharacters(in: .whitespaces)
        if !reps.isEmpty { parts.append("\(reps) reps") }
        if let rpe = set.rpe?.trimmingCharacters(in: .whitespaces), !rpe.isEmpty {
            parts.append("RPE \(rpe)")
        }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }
}

private struct ProgressHistoryEmptyCard: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color.deltsMutedText)
            Text("No workout history yet")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)
            Text("Finish a session with the timer on Home and it shows here with time taken and calories burned.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 18)
        .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.28), lineWidth: 0.5)
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

private struct MetricDateTick: Identifiable {
    let id: Int
    let date: Date
    let xRatio: CGFloat
}

private struct ProgressEmptyState: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.deltsMutedText)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.deltsPanel.opacity(0.24), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ProgressMetricCard: View {
    let title: String
    let unit: String
    let values: [ProgressMetricPoint]
    let range: ProgressRange
    let currentValue: Double?
    let goalValue: Double?
    let goalText: String?
    let actionTitle: String
    let actionSystemImage: String
    let onLog: () -> Void

    private var latestValue: Double? {
        values.last?.value
    }

    private var displayedCurrentValue: Double? {
        currentValue ?? latestValue
    }

    private var netChangeValue: Double? {
        guard let first = values.first?.value,
              let last = latestValue
        else { return nil }
        return last - first
    }

    private var averageValue: Double? {
        guard !values.isEmpty else { return displayedCurrentValue }
        return values.reduce(0) { $0 + $1.value } / Double(values.count)
    }

    private var graphValues: [ProgressMetricPoint] {
        Self.reducedGraphValues(from: values, limit: range.graphPointLimit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)

                Spacer()

                Button(action: onLog) {
                    Label(actionTitle, systemImage: actionSystemImage)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.deltsAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }
                .buttonStyle(.plain)
                .deltsPressable()
            }

            HStack(spacing: 10) {
                MetricStatTile(title: "Current", value: displayedCurrentValue.map(formatted) ?? "--")
                MetricStatTile(title: "Goal", value: goalText ?? goalValue.map(formatted) ?? "--")
                MetricStatTile(title: "Net Change", value: netChangeValue.map(formattedSigned) ?? "--")
                MetricStatTile(title: "Average", value: averageValue.map(formatted) ?? "--")
            }

            MetricLineGraph(points: graphValues, unit: unit, goalValue: goalValue)
                .frame(height: 222)
        }
        .padding(18)
        .background(Color.deltsPanel.opacity(0.30), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.6)
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

    private static func reducedGraphValues(from values: [ProgressMetricPoint], limit: Int?) -> [ProgressMetricPoint] {
        let sortedValues = values.sorted { $0.date < $1.date }
        guard let limit,
              sortedValues.count > limit,
              limit > 2
        else { return sortedValues }

        let middleValues = Array(sortedValues.dropFirst().dropLast())
        guard !middleValues.isEmpty else { return sortedValues }

        let bucketCount = max(limit - 2, 1)
        var reducedValues = [sortedValues[0]]

        for bucket in 0..<bucketCount {
            let startIndex = bucket * middleValues.count / bucketCount
            let endIndex = (bucket + 1) * middleValues.count / bucketCount
            guard startIndex < endIndex else { continue }

            let bucketValues = middleValues[startIndex..<endIndex]
            let average = bucketValues.reduce(0) { $0 + $1.value } / Double(bucketValues.count)
            let midpointIndex = bucketValues.startIndex + bucketValues.count / 2

            reducedValues.append(
                ProgressMetricPoint(
                    date: middleValues[midpointIndex].date,
                    value: average
                )
            )
        }

        reducedValues.append(sortedValues[sortedValues.count - 1])
        return reducedValues
    }
}

private struct MetricStatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.monospacedDigit().weight(.black))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.62)

            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
    }
}

private struct MetricLineGraph: View {
    let points: [ProgressMetricPoint]
    let unit: String
    let goalValue: Double?

    private let axisWidth: CGFloat = 36
    private let dateLabelHeight: CGFloat = 32
    private var dateLabelWidth: CGFloat { usesMonthYearDateLabels ? 66 : 56 }
    private var lineWidth: CGFloat { points.count > 18 ? 2.8 : 3.2 }
    private var pointSize: CGFloat { points.count > 18 ? 7 : 9 }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let plotWidth = max(size.width - axisWidth, 1)
            let plotHeight = max(size.height - dateLabelHeight, 1)
            let domain = yDomain
            let spread = max(domain.max - domain.min, 1)
            let xAxisTicks = dateTicks

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.deltsCard.opacity(0.42))

                MetricGraphGrid(verticalLineCount: max(xAxisTicks.count, 2))
                    .frame(width: plotWidth, height: plotHeight)

                if let goalValue {
                    let y = yPosition(for: goalValue, plotHeight: plotHeight, domain: domain, spread: spread)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: plotWidth, y: y))
                    }
                    .stroke(
                        Color.deltsAccent.opacity(0.60),
                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [7, 7])
                    )
                }

                Path { path in
                    guard !points.isEmpty else { return }
                    for index in points.indices {
                        let x = xPosition(for: points[index], index: index, plotWidth: plotWidth)
                        let y = yPosition(for: points[index].value, plotHeight: plotHeight, domain: domain, spread: spread)
                        if index == points.startIndex {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.deltsAccent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                ForEach(points.indices, id: \.self) { index in
                    let x = xPosition(for: points[index], index: index, plotWidth: plotWidth)
                    let y = yPosition(for: points[index].value, plotHeight: plotHeight, domain: domain, spread: spread)
                    Circle()
                        .fill(Color.deltsAccent)
                        .frame(width: pointSize, height: pointSize)
                        .position(x: x, y: y)
                }

                ForEach(0..<3, id: \.self) { index in
                    let value = axisValue(at: index, domain: domain)
                    let y = yPosition(for: value, plotHeight: plotHeight, domain: domain, spread: spread)
                    Text(axisLabel(for: value))
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                        .frame(width: axisWidth, alignment: .leading)
                        .position(x: plotWidth + axisWidth / 2 + 4, y: y)
                }

                ForEach(xAxisTicks) { tick in
                    Text(dateLabel(for: tick.date))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.64)
                        .frame(width: dateLabelWidth)
                        .position(
                            x: dateLabelXPosition(for: tick.xRatio * plotWidth, plotWidth: plotWidth),
                            y: plotHeight + dateLabelHeight * 0.62
                        )
                }
            }
        }
    }

    private var yDomain: (min: Double, max: Double) {
        var values = points.map(\.value)
        if let goalValue {
            values.append(goalValue)
        }
        guard let minValue = values.min(), let maxValue = values.max() else {
            return (0, 1)
        }
        let spread = max(maxValue - minValue, unit == "%" ? 1 : 2)
        let padding = spread * 0.16
        return (minValue - padding, maxValue + padding)
    }

    private var dateTicks: [MetricDateTick] {
        guard !points.isEmpty else { return [] }
        let firstDate = points[0].date
        let lastDate = points[points.count - 1].date
        let duration = max(lastDate.timeIntervalSince(firstDate), 0)

        return (0..<4).map { index in
            let ratio = CGFloat(index) / 3
            return MetricDateTick(
                id: index,
                date: firstDate.addingTimeInterval(duration * Double(ratio)),
                xRatio: ratio
            )
        }
    }

    private var usesMonthYearDateLabels: Bool {
        guard let firstDate = points.first?.date,
              let lastDate = points.last?.date
        else { return false }
        return !Calendar.current.isDate(firstDate, equalTo: lastDate, toGranularity: .year)
    }

    private func dateLabel(for date: Date) -> String {
        if usesMonthYearDateLabels {
            return Self.monthYearFormatter.string(from: date)
        }
        return Self.monthDayFormatter.string(from: date)
    }

    private func dateLabelXPosition(for x: CGFloat, plotWidth: CGFloat) -> CGFloat {
        let halfLabelWidth = dateLabelWidth / 2
        guard plotWidth > halfLabelWidth * 2 else { return plotWidth / 2 }
        return min(max(x, halfLabelWidth), plotWidth - halfLabelWidth)
    }

    private func xPosition(for point: ProgressMetricPoint, index: Int, plotWidth: CGFloat) -> CGFloat {
        guard let firstDate = points.first?.date,
              let lastDate = points.last?.date
        else { return plotWidth / 2 }

        let duration = lastDate.timeIntervalSince(firstDate)
        guard duration > 0 else {
            return points.count == 1 ? plotWidth / 2 : CGFloat(index) / CGFloat(points.count - 1) * plotWidth
        }

        return CGFloat(point.date.timeIntervalSince(firstDate) / duration) * plotWidth
    }

    private func yPosition(
        for value: Double,
        plotHeight: CGFloat,
        domain: (min: Double, max: Double),
        spread: Double
    ) -> CGFloat {
        plotHeight - CGFloat((value - domain.min) / spread) * plotHeight
    }

    private func axisValue(at index: Int, domain: (min: Double, max: Double)) -> Double {
        switch index {
        case 0:
            return domain.max
        case 1:
            return (domain.max + domain.min) / 2
        default:
            return domain.min
        }
    }

    private func axisLabel(for value: Double) -> String {
        if unit == "%" {
            return String(format: "%.0f", value)
        }
        if abs(value.rounded() - value) < 0.05 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }()

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.dateFormat = "MMM ''yy"
        return formatter
    }()
}

private struct MetricGraphGrid: View {
    private let horizontalLineCount = 5
    let verticalLineCount: Int

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                ForEach(0..<horizontalLineCount, id: \.self) { index in
                    let y = CGFloat(index) / CGFloat(horizontalLineCount - 1) * size.height
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    .stroke(
                        Color.deltsHairline.opacity(index == horizontalLineCount - 1 ? 0.56 : 0.34),
                        lineWidth: index == horizontalLineCount - 1 ? 1.0 : 0.7
                    )
                }

                ForEach(0..<verticalLineCount, id: \.self) { index in
                    let denominator = max(verticalLineCount - 1, 1)
                    let x = CGFloat(index) / CGFloat(denominator) * size.width
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    .stroke(
                        Color.deltsHairline.opacity(0.38),
                        style: StrokeStyle(lineWidth: 0.85, dash: [3, 4])
                    )
                }
            }
        }
        .allowsHitTesting(false)
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

private struct BodyLogSheet: View {
    let snapshots: [ProgressMetricSnapshot]
    let usesImperialUnits: Bool
    let weightText: (Double) -> String
    let bodyFatText: (ProgressMetricSnapshot) -> String
    let update: (ProgressMetricSnapshot) -> Void
    let delete: (ProgressMetricSnapshot) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editingSnapshot: ProgressMetricSnapshot?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if snapshots.isEmpty {
                        ProgressEmptyState(text: "No weight or body fat logs in this range.")
                    } else {
                        ForEach(snapshots) { snapshot in
                            MetricHistoryRow(
                                snapshot: snapshot,
                                weightText: snapshot.weightKg.map(weightText) ?? "--",
                                bodyFatText: bodyFatText(snapshot),
                                edit: { editingSnapshot = snapshot },
                                delete: { delete(snapshot) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .deltsScreen()
            .navigationTitle("Body Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(item: $editingSnapshot) { snapshot in
                MetricSnapshotEditSheet(
                    snapshot: snapshot,
                    usesImperialUnits: usesImperialUnits
                ) { updated in
                    update(updated)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private enum ProgressMeasurementSystem: String, CaseIterable, Hashable {
    case metric
    case imperial

    var title: String {
        switch self {
        case .metric:
            return "Metric"
        case .imperial:
            return "Imperial"
        }
    }

    init(storedValue: String) {
        self = ProgressMeasurementSystem(rawValue: storedValue) ?? .metric
    }
}

private struct ProgressMassWheelSheet: View {
    let title: String
    let metricRange: ClosedRange<Int>
    let imperialRange: ClosedRange<Int>
    let save: (Double, ProgressMeasurementSystem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSystem: ProgressMeasurementSystem
    @State private var whole: Int
    @State private var decimal: Int

    init(
        title: String,
        initialKilograms: Double,
        initialSystem: ProgressMeasurementSystem,
        metricRange: ClosedRange<Int>,
        imperialRange: ClosedRange<Int>,
        save: @escaping (Double, ProgressMeasurementSystem) -> Void
    ) {
        let initialDisplayValue = initialSystem == .metric ? initialKilograms : initialKilograms * 2.2046226218
        let parts = progressDecimalParts(for: initialDisplayValue, range: initialSystem == .metric ? metricRange : imperialRange)
        self.title = title
        self.metricRange = metricRange
        self.imperialRange = imperialRange
        self.save = save
        _selectedSystem = State(initialValue: initialSystem)
        _whole = State(initialValue: parts.whole)
        _decimal = State(initialValue: parts.decimal)
    }

    private var unit: String {
        selectedSystem == .metric ? "kg" : "lb"
    }

    private var wholeOptions: [Int] {
        Array(selectedSystem == .metric ? metricRange : imperialRange)
    }

    private var selectedDisplayValue: Double {
        Double(whole) + (Double(decimal) / 10)
    }

    private var selectedKilograms: Double {
        selectedSystem == .metric ? selectedDisplayValue : selectedDisplayValue / 2.2046226218
    }

    private var systemBinding: Binding<ProgressMeasurementSystem> {
        Binding {
            selectedSystem
        } set: { newSystem in
            let kilograms = selectedKilograms
            selectedSystem = newSystem
            setDisplayValue(newSystem == .metric ? kilograms : kilograms * 2.2046226218)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Unit", selection: systemBinding) {
                    ForEach(ProgressMeasurementSystem.allCases, id: \.self) { system in
                        Text(system.title).tag(system)
                    }
                }
                .pickerStyle(.segmented)

                Text("\(progressFormatDecimal(selectedDisplayValue)) \(unit)")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 10) {
                    ProgressWheelColumn(title: "Whole", selection: $whole, values: wholeOptions) { "\($0)" }
                    ProgressWheelColumn(title: "Decimal", selection: $decimal, values: Array(0...9)) { ".\($0)" }

                    Text(unit)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText)
                        .frame(width: 48)
                }
                .frame(height: 190)
            }
            .padding(.top, 18)
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .background(DeltsBackground())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        save(selectedKilograms, selectedSystem)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.height(420), .medium])
        .presentationDragIndicator(.visible)
    }

    private func setDisplayValue(_ value: Double) {
        let range = selectedSystem == .metric ? metricRange : imperialRange
        let parts = progressDecimalParts(for: value, range: range)
        whole = parts.whole
        decimal = parts.decimal
    }
}

private struct ProgressBodyFatRangeSheet: View {
    let title: String
    let initialValue: Double
    let sex: String
    let save: (Double, Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var usesExactValue: Bool
    @State private var whole: Int
    @State private var decimal: Int

    init(
        title: String,
        initialValue: Double,
        initialIsExact: Bool,
        sex: String,
        save: @escaping (Double, Bool) -> Void
    ) {
        self.title = title
        self.initialValue = initialValue
        self.sex = sex
        self.save = save

        let parts = progressDecimalParts(for: initialValue, range: 0...60)
        _usesExactValue = State(initialValue: initialIsExact)
        _whole = State(initialValue: parts.whole)
        _decimal = State(initialValue: parts.decimal)
    }

    private var selectedRange: ProgressBodyFatRange {
        ProgressBodyFatRange.matching(initialValue, sex: sex)
    }

    private var ranges: [ProgressBodyFatRange] {
        ProgressBodyFatRange.options(for: sex)
    }

    private var exactValue: Double {
        Double(whole) + (Double(decimal) / 10)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ProgressBodyFatModeToggle(isExactMode: $usesExactValue)

                    if usesExactValue {
                        ProgressBodyFatExactWheelPicker(
                            whole: $whole,
                            decimal: $decimal,
                            selectedValue: exactValue
                        )
                        .transition(.opacity)
                    } else {
                        ForEach(ranges) { range in
                            Button {
                                save(range.storedValue, false)
                                dismiss()
                            } label: {
                                ProgressBodyFatRangeCard(
                                    range: range,
                                    sex: sex,
                                    isSelected: range.id == selectedRange.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .background(DeltsBackground())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if usesExactValue {
                            save(exactValue, true)
                        }
                        dismiss()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
                }
            }
        }
        .presentationDetents(usesExactValue ? [.height(420), .medium] : [.large])
        .presentationDragIndicator(.visible)
    }
}

private struct ProgressBodyFatModeToggle: View {
    @Binding var isExactMode: Bool

    var body: some View {
        Toggle(isOn: $isExactMode) {
            Label("Exact value", systemImage: "number")
                .font(.headline.weight(.heavy))
                .foregroundStyle(Color.deltsCharcoal)
        }
        .toggleStyle(.switch)
        .tint(Color.deltsAccent)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.deltsPanel.opacity(0.24), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.6)
        }
    }
}

private struct ProgressBodyFatExactWheelPicker: View {
    @Binding var whole: Int
    @Binding var decimal: Int
    let selectedValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("\(progressFormatDecimal(selectedValue))%")
                .font(.title2.monospacedDigit().weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 10) {
                ProgressWheelColumn(title: "Whole", selection: $whole, values: Array(0...60)) { "\($0)" }
                ProgressWheelColumn(title: "Decimal", selection: $decimal, values: Array(0...9)) { ".\($0)" }

                Text("%")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .frame(width: 48)
            }
            .frame(height: 190)
        }
        .padding(.top, 18)
        .padding(.horizontal, 14)
        .padding(.bottom, 18)
        .background(Color.deltsPanel.opacity(0.22), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.deltsAccent.opacity(0.28), lineWidth: 1)
        }
    }
}

private struct ProgressBodyFatRangeCard: View {
    let range: ProgressBodyFatRange
    let sex: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Image(range.assetName(for: sex))
                    .resizable()
                    .scaledToFill()
                    .frame(height: 158)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.deltsAccent)
                        .padding(10)
                        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 2)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(range.title)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Color.deltsCharcoal)

                Text(range.summary)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isSelected ? Color.deltsAccent.opacity(0.18) : Color.deltsPanel.opacity(0.74))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? Color.deltsAccent.opacity(0.72) : Color.deltsMutedText.opacity(0.12), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(range.title), \(range.summary)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

private struct ProgressBodyFatRange: Identifiable {
    let id: String
    let title: String
    let lowerBound: Double
    let upperBound: Double?
    let storedValue: Double
    let summary: String

    private static let ranges: [ProgressBodyFatRange] = [
        ProgressBodyFatRange(id: "06_09", title: "6-9%", lowerBound: 6, upperBound: 9, storedValue: 8, summary: "Very lean"),
        ProgressBodyFatRange(id: "10_13", title: "10-13%", lowerBound: 10, upperBound: 13, storedValue: 12, summary: "Lean"),
        ProgressBodyFatRange(id: "14_17", title: "14-17%", lowerBound: 14, upperBound: 17, storedValue: 16, summary: "Fit"),
        ProgressBodyFatRange(id: "18_22", title: "18-22%", lowerBound: 18, upperBound: 22, storedValue: 20, summary: "Average"),
        ProgressBodyFatRange(id: "23_27", title: "23-27%", lowerBound: 23, upperBound: 27, storedValue: 25, summary: "Soft"),
        ProgressBodyFatRange(id: "28_32", title: "28-32%", lowerBound: 28, upperBound: 32, storedValue: 30, summary: "Fuller"),
        ProgressBodyFatRange(id: "33_plus", title: "33%+", lowerBound: 33, upperBound: nil, storedValue: 36, summary: "High")
    ]

    static func options(for sex: String) -> [ProgressBodyFatRange] {
        ranges
    }

    static func matching(_ value: Double, sex: String) -> ProgressBodyFatRange {
        let ranges = options(for: sex)
        let roundedValue = value.rounded()
        if let exactRange = ranges.first(where: { range in
            guard roundedValue >= range.lowerBound else { return false }
            return roundedValue <= (range.upperBound ?? .greatestFiniteMagnitude)
        }) {
            return exactRange
        }
        return roundedValue < (ranges.first?.lowerBound ?? 0) ? ranges[0] : ranges[ranges.count - 1]
    }

    func assetName(for sex: String) -> String {
        let normalizedSex = sex.localizedCaseInsensitiveContains("female") ? "female" : "male"
        return "bodyfat_\(normalizedSex)_\(id)"
    }
}

private struct ProgressWheelColumn: View {
    let title: String
    @Binding var selection: Int
    let values: [Int]
    let label: (Int) -> String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)

            Picker(title, selection: $selection) {
                ForEach(values, id: \.self) { value in
                    Text(label(value))
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity)
        .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
        }
    }
}

private func progressFormatDecimal(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(1)))
}

private func progressDecimalParts(for value: Double, range: ClosedRange<Int>) -> (whole: Int, decimal: Int) {
    let minimumTenths = range.lowerBound * 10
    let maximumTenths = (range.upperBound * 10) + 9
    let roundedTenths = Int((value * 10).rounded())
    let tenths = min(max(roundedTenths, minimumTenths), maximumTenths)
    let whole = min(max(tenths / 10, range.lowerBound), range.upperBound)
    let decimal = tenths % 10
    return (whole, decimal)
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
