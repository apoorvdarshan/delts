import SwiftData
import SwiftUI

struct ProgressTabView: View {
    @Query(sort: \CompletedWorkout.date, order: .reverse) private var workouts: [CompletedWorkout]
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @AppStorage("profile_measurement_system") private var measurementSystemRaw = "metric"
    @State private var selectedRange: ProgressRange = .month
    @State private var snapshots: [ProgressMetricSnapshot] = ProgressMetricStore.load()

    private var filteredSnapshots: [ProgressMetricSnapshot] {
        selectedRange.filter(snapshots).sorted { $0.date < $1.date }
    }

    private var filteredWorkouts: [CompletedWorkout] {
        selectedRange.filter(workouts)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    rangePicker
                    metricGraphs
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
            .onAppear(perform: recordCurrentSnapshot)
            .onChange(of: profiles.first?.currentWeightKG) {
                recordCurrentSnapshot()
            }
            .onChange(of: profiles.first?.currentBodyFatPercentage) {
                recordCurrentSnapshot()
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
                values: filteredSnapshots.map { snapshot in
                    ProgressMetricPoint(date: snapshot.date, value: usesImperialUnits ? snapshot.weightKg * 2.2046226218 : snapshot.weightKg)
                }
            )

            ProgressMetricCard(
                title: "Body Fat",
                unit: "%",
                values: filteredSnapshots.map { ProgressMetricPoint(date: $0.date, value: $0.bodyFat) }
            )
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
        snapshots = ProgressMetricStore.record(weightKg: profile.currentWeightKG, bodyFat: profile.currentBodyFatPercentage, in: snapshots)
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
}

private struct ProgressMetricSnapshot: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var weightKg: Double
    var bodyFat: Double
}

private enum ProgressMetricStore {
    private static let key = "delts.progressMetrics.v1"

    static func load() -> [ProgressMetricSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let snapshots = try? JSONDecoder().decode([ProgressMetricSnapshot].self, from: data)
        else {
            return []
        }
        return snapshots
    }

    static func record(weightKg: Double, bodyFat: Double, in current: [ProgressMetricSnapshot]) -> [ProgressMetricSnapshot] {
        var snapshots = current
        let today = Calendar.current.startOfDay(for: Date())
        if let index = snapshots.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            snapshots[index].date = Date()
            snapshots[index].weightKg = weightKg
            snapshots[index].bodyFat = bodyFat
        } else {
            snapshots.append(ProgressMetricSnapshot(date: Date(), weightKg: weightKg, bodyFat: bodyFat))
        }
        save(snapshots)
        return snapshots
    }

    private static func save(_ snapshots: [ProgressMetricSnapshot]) {
        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

private struct ProgressMetricPoint: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let value: Double
}

private struct ProgressMetricCard: View {
    let title: String
    let unit: String
    let values: [ProgressMetricPoint]

    private var latestValue: Double? {
        values.last?.value
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
