import SwiftData
import SwiftUI

struct WorkoutsView: View {
    @Query(sort: \CompletedWorkout.date, order: .reverse) private var workouts: [CompletedWorkout]
    @State private var selectedMode: WorkoutsMode = .library

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modePicker

                Group {
                    switch selectedMode {
                    case .library:
                        ExerciseLibraryBrowserView()
                    case .history:
                        WorkoutHistoryListView(workouts: workouts)
                    }
                }
            }
            .background(WorkoutsScreenBackground())
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var modePicker: some View {
        Picker("Workouts", selection: $selectedMode) {
            ForEach(WorkoutsMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }
}

private enum WorkoutsMode: String, CaseIterable, Identifiable {
    case library
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .library: return "Library"
        case .history: return "History"
        }
    }
}

private struct ExerciseLibraryBrowserView: View {
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var selectedLevel: ExperienceLevel?
    @State private var selectedGoal: FitnessGoal?
    @State private var selectedEquipment: Equipment?
    @State private var selectedEquipmentFamily: ExerciseEquipmentFamily = .all
    @State private var selectedSort: ExerciseLibrarySort = .bodyPart
    @State private var generatedPlan: WorkoutPlan?

    private let service = ExerciseLibraryService.shared

    private var items: [ExerciseLibraryItem] {
        service.filtered(
            muscleGroup: selectedMuscleGroup,
            level: selectedLevel,
            goal: selectedGoal,
            equipment: selectedEquipment,
            equipmentFamily: selectedEquipmentFamily,
            sort: selectedSort,
            searchText: searchText
        )
    }

    private var hasActiveFilters: Bool {
        !searchText.isEmpty ||
            selectedMuscleGroup != nil ||
            selectedLevel != nil ||
            selectedGoal != nil ||
            selectedEquipment != nil ||
            selectedEquipmentFamily != .all ||
            selectedSort != .bodyPart
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                librarySummary
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 18)

                filters
                    .padding(.bottom, 18)

                if items.isEmpty {
                    ContentUnavailableView(
                        "No exercises match",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Reset filters or search a different body part, machine, or exercise.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .padding(.horizontal, 20)
                } else {
                    ResultsHeader(
                        count: items.count,
                        noun: "exercise",
                        subtitle: selectedSort.title,
                        trailingTitle: "Offline media"
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)

                    ForEach(items) { item in
                        NavigationLink {
                            ExerciseLibraryDetailView(item: item)
                        } label: {
                            ExerciseLibraryRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)

                        if item.id != items.last?.id {
                            Divider()
                                .padding(.leading, 144)
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .padding(.bottom, 112)
        }
        .deltsScreen()
        .contentMargins(.bottom, 104, for: .scrollContent)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
        .navigationDestination(item: $generatedPlan) { plan in
            WorkoutPlanView(plan: plan)
        }
    }

    private var librarySummary: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Exercise library")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text("\(service.exercises.count) offline exercises")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("\(items.count) shown")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Button {
                generatedPlan = service.makePlan(from: items)
            } label: {
                Label("Build Top \(min(items.count, 8))", systemImage: "wand.and.stars")
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .tint(Color.deltsAccent)
            .disabled(items.isEmpty)
        }
        .padding(.vertical, 4)
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    BodyPartFilterChip(
                        title: "All",
                        systemImage: "square.grid.2x2",
                        isSelected: selectedMuscleGroup == nil
                    ) {
                        withAnimation(.snappy) {
                            selectedMuscleGroup = nil
                        }
                    }

                    ForEach(MuscleGroup.allCases) { group in
                        BodyPartFilterChip(
                            title: group.title,
                            systemImage: group.icon,
                            isSelected: selectedMuscleGroup == group
                        ) {
                            withAnimation(.snappy) {
                                selectedMuscleGroup = group
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterMenu(
                        title: "Level",
                        value: selectedLevel?.title ?? "All",
                        systemImage: "chart.bar.fill"
                    ) {
                        Button("All Levels") { selectedLevel = nil }
                        ForEach(ExperienceLevel.allCases) { level in
                            Button(level.title) { selectedLevel = level }
                        }
                    }

                    filterMenu(
                        title: "Goal",
                        value: selectedGoal?.title ?? "All",
                        systemImage: "target"
                    ) {
                        Button("All Goals") { selectedGoal = nil }
                        ForEach(FitnessGoal.profileCases + [.beginnerForm]) { goal in
                            Button(goal.title) { selectedGoal = goal }
                        }
                    }

                    filterMenu(
                        title: "Equipment",
                        value: equipmentFilterTitle,
                        systemImage: "dumbbell.fill"
                    ) {
                        Button("All Equipment") {
                            selectedEquipment = nil
                            selectedEquipmentFamily = .all
                        }
                        Section("Family") {
                            ForEach(ExerciseEquipmentFamily.allCases.filter { $0 != .all }) { family in
                                Button(family.title) {
                                    selectedEquipment = nil
                                    selectedEquipmentFamily = family
                                }
                            }
                        }
                        Section("Specific") {
                            ForEach(Equipment.allCases) { equipment in
                                Button(equipment.title) {
                                    selectedEquipment = equipment
                                    selectedEquipmentFamily = .all
                                }
                            }
                        }
                    }

                    filterMenu(
                        title: "Sort",
                        value: selectedSort.title,
                        systemImage: "arrow.up.arrow.down"
                    ) {
                        ForEach(ExerciseLibrarySort.allCases) { sort in
                            Button(sort.title) { selectedSort = sort }
                        }
                    }

                    if hasActiveFilters {
                        Button {
                            withAnimation(.snappy) {
                                resetFilters()
                            }
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(Color.deltsInferno)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var equipmentFilterTitle: String {
        if let selectedEquipment {
            return selectedEquipment.title
        }
        if selectedEquipmentFamily != .all {
            return selectedEquipmentFamily.title
        }
        return "All"
    }

    private func resetFilters() {
        searchText = ""
        selectedMuscleGroup = nil
        selectedLevel = nil
        selectedGoal = nil
        selectedEquipment = nil
        selectedEquipmentFamily = .all
        selectedSort = .bodyPart
    }

    private func filterMenu<Content: View>(
        title: String,
        value: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            Label {
                Text(value == "All" ? title : "\(title): \(value)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            } icon: {
                Image(systemName: systemImage)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(.secondary)
    }
}

private struct WorkoutHistoryListView: View {
    let workouts: [CompletedWorkout]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if workouts.isEmpty {
                    ContentUnavailableView(
                        "No completed workouts yet",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Generate a plan, start it, then finish to create your first log.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 360)
                    .padding(.horizontal, 20)
                } else {
                    ResultsHeader(
                        count: workouts.count,
                        noun: "workout",
                        subtitle: "Completed",
                        trailingTitle: "Local logs"
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 4)

                    ForEach(workouts) { workout in
                        NavigationLink {
                            CompletedWorkoutDetailView(workout: workout)
                        } label: {
                            CompletedWorkoutRow(workout: workout)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)

                        if workout.id != workouts.last?.id {
                            Divider()
                                .padding(.leading, 88)
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .padding(.bottom, 112)
        }
        .deltsScreen()
        .contentMargins(.bottom, 104, for: .scrollContent)
    }
}

private struct ResultsHeader: View {
    let count: Int
    let noun: String
    let subtitle: String
    let trailingTitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count) \(count == 1 ? noun : "\(noun)s")")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .textCase(nil)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            }

            Spacer()

            Text(trailingTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(nil)
        }
        .padding(.top, 6)
    }
}

private struct BodyPartFilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            } icon: {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.deltsAccent : Color.clear, in: Capsule())
        .overlay {
            Capsule()
                .stroke(isSelected ? Color.deltsAccent.opacity(0.75) : Color(uiColor: .separator).opacity(0.36), lineWidth: 0.75)
        }
        .contentShape(Capsule())
    }
}

private struct ExerciseLibraryRow: View {
    let item: ExerciseLibraryItem

    var body: some View {
        HStack(spacing: 16) {
            thumbnail

            VStack(alignment: .leading, spacing: 9) {
                Text(item.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text("\(item.muscleGroup.title) - \(item.equipment.title) - \(item.level.title)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)

                HStack(spacing: 8) {
                    LibraryTag(title: item.goal.title, systemImage: "target", tint: .deltsAccent)
                    LibraryTag(title: item.machineLabel, systemImage: "dumbbell.fill", tint: .deltsInferno)
                    if item.imagePaths.count > 1 {
                        LibraryTag(title: "\(item.imagePaths.count) media", systemImage: "photo.stack", tint: .deltsAcidGreen)
                    }
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var thumbnail: some View {
        AnimatedExerciseVisual(
            muscleGroup: item.muscleGroup,
            assetName: item.visualAssetName,
            exerciseName: item.name,
            imagePaths: item.imagePaths,
            equipment: item.equipment,
            height: 104,
            fillsWidth: false
        )
        .frame(width: 104, height: 104)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityHidden(true)
    }
}

private struct CompletedWorkoutRow: View {
    let workout: CompletedWorkout

    var body: some View {
        HStack(spacing: 14) {
            WorkoutHistoryGlyph(workout: workout)

            VStack(alignment: .leading, spacing: 8) {
                Text(workout.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                historySummaryStrip
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var logs: [CompletedExerciseLog] {
        workout.exerciseLogs
    }

    private var completedSets: Int {
        logs.reduce(0) { total, exercise in
            total + exercise.sets.filter(\.completed).count
        }
    }

    private var totalSets: Int {
        logs.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }

    private var historySummaryStrip: some View {
        HStack(spacing: 10) {
            HistorySummaryItem(value: "\(logs.count)", label: logs.count == 1 ? "exercise" : "exercises", systemImage: "figure.strengthtraining.traditional")
            HistorySummaryItem(value: "\(completedSets)/\(totalSets)", label: "sets", systemImage: "checkmark.circle")
            HistorySummaryItem(value: "\(workout.durationMinutes)m", label: "duration", systemImage: "clock")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }
}

private struct WorkoutHistoryGlyph: View {
    let workout: CompletedWorkout

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.deltsAccent.opacity(0.12))

            if let iconName {
                Image(systemName: iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.deltsAccent)
            } else {
                Text(initial)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
            }
        }
        .frame(width: 58, height: 58)
        .accessibilityHidden(true)
    }

    private var primaryExercise: CompletedExerciseLog? {
        workout.exerciseLogs.first
    }

    private var iconName: String? {
        guard let target = primaryExercise?.targetMuscle else { return nil }
        return MuscleGroup(rawValue: target)?.icon
    }

    private var initial: String {
        let trimmedTitle = workout.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.first.map { String($0).uppercased() } ?? "W"
    }
}

private struct HistorySummaryItem: View {
    let value: String
    let label: String
    let systemImage: String

    var body: some View {
        Label {
            Text("\(value) \(label)")
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        } icon: {
            Image(systemName: systemImage)
        }
        .labelStyle(.titleAndIcon)
    }
}

private struct LibraryTag: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(tint)
            .lineLimit(1)
            .accessibilityElement(children: .combine)
    }
}

private struct ExerciseLibraryDetailView: View {
    let item: ExerciseLibraryItem
    @State private var activePlan: WorkoutPlan?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                detailHero

                VStack(alignment: .leading, spacing: 24) {
                    DetailMetricGrid(item: item, restText: restText)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Form tip")
                            .font(.headline.weight(.semibold))
                        Text(item.formTip)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 0) {
                        DetailInfoRow(title: "Goal", value: item.goal.title, systemImage: "target")
                        Divider()
                        DetailInfoRow(title: "Equipment", value: "\(item.equipment.title) - \(item.machineLabel)", systemImage: "dumbbell.fill")
                        Divider()
                        DetailInfoRow(title: "Source", value: item.source, systemImage: "checkmark.seal")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 126)
            }
        }
        .deltsScreen()
        .contentMargins(.bottom, 104, for: .scrollContent)
        .safeAreaInset(edge: .bottom) {
            startExerciseBar
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $activePlan) { plan in
            ActiveWorkoutView(plan: plan)
        }
    }

    private var detailHero: some View {
        AnimatedExerciseVisual(
            muscleGroup: item.muscleGroup,
            assetName: item.visualAssetName,
            exerciseName: item.name,
            imagePaths: item.imagePaths,
            equipment: item.equipment,
            height: 326
        )
        .frame(maxWidth: .infinity)
        .overlay {
            LinearGradient(
                colors: [.clear, .black.opacity(0.18), .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 8) {
                if item.imagePaths.count > 1 {
                    Label("\(item.imagePaths.count) media", systemImage: "photo.stack")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Text(item.name)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)

                Text("\(item.muscleGroup.title) - \(item.equipment.title) - \(item.level.title)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(item.name) exercise visual"))
    }

    private var startExerciseBar: some View {
        Button {
            activePlan = item.singleExercisePlan()
        } label: {
            Label("Start Exercise", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(Color.deltsAccent)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.bar)
    }

    private var restText: String {
        item.restSeconds == 0 ? "--" : "\(item.restSeconds)s"
    }
}

private struct DetailMetricGrid: View {
    let item: ExerciseLibraryItem
    let restText: String

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                DetailMetric(title: "Sets", value: "\(item.sets)", systemImage: "number")
                Divider().frame(height: 46)
                DetailMetric(title: "Reps", value: item.reps, systemImage: "repeat")
                Divider().frame(height: 46)
                DetailMetric(title: "Rest", value: restText, systemImage: "timer")
            }

            Divider()

            HStack(spacing: 0) {
                DetailMetric(title: "Level", value: item.level.title, systemImage: "chart.bar.fill")
                Divider().frame(height: 46)
                DetailMetric(title: "Body", value: item.muscleGroup.title, systemImage: item.muscleGroup.icon)
                Divider().frame(height: 46)
                DetailMetric(title: "Equipment", value: item.equipment.title, systemImage: "dumbbell.fill")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DetailMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsAccent)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }
}

private struct DetailInfoRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 28, height: 28)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 12)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
    }
}

struct CompletedWorkoutDetailView: View {
    let workout: CompletedWorkout

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                detailHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 18)

                ForEach(workout.exerciseLogs) { exercise in
                    CompletedExerciseLogSection(exercise: exercise)

                    if exercise.id != workout.exerciseLogs.last?.id {
                        Divider()
                            .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 112)
        }
        .deltsScreen()
        .contentMargins(.bottom, 104, for: .scrollContent)
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var completedSets: Int {
        workout.exerciseLogs.reduce(0) { total, exercise in
            total + exercise.sets.filter(\.completed).count
        }
    }

    private var totalSets: Int {
        workout.exerciseLogs.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                WorkoutHistoryGlyph(workout: workout)

                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.title)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.76)

                    Text(workout.date.formatted(date: .complete, time: .shortened))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.deltsAccent)
                }
            }

            Text(workout.planSummary)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 0) {
                WorkoutSummaryMetric(value: "\(workout.exerciseLogs.count)", title: "Exercises")
                Divider().frame(height: 38)
                WorkoutSummaryMetric(value: "\(completedSets)/\(totalSets)", title: "Sets")
                Divider().frame(height: 38)
                WorkoutSummaryMetric(value: "\(workout.durationMinutes)m", title: "Duration")
            }
        }
    }
}

private struct CompletedExerciseLogSection: View {
    let exercise: CompletedExerciseLog

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("\(exercise.targetMuscle) - \(exercise.equipment)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                Text("\(completedSets)/\(exercise.sets.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .background(Color.deltsAccent.opacity(0.12), in: Capsule())
            }

            VStack(spacing: 0) {
                ForEach(exercise.sets) { set in
                    CompletedSetLogRow(set: set)

                    if set.id != exercise.sets.last?.id {
                        Divider()
                            .padding(.leading, 34)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var completedSets: Int {
        exercise.sets.filter(\.completed).count
    }
}

private struct CompletedSetLogRow: View {
    let set: CompletedSetLog

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(set.completed ? Color.deltsAccent : .secondary)
                .accessibilityHidden(true)

            Text("Set \(set.setNumber)")
                .foregroundStyle(.primary)

            Spacer()

            Text(weightRepText)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(.vertical, 10)
    }

    private var weightRepText: String {
        let weight = set.weight.isEmpty ? "--" : set.weight
        let reps = set.reps.isEmpty ? "--" : set.reps
        return "\(weight) x \(reps)"
    }
}

private struct WorkoutSummaryMetric: View {
    let value: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }
}

private struct WorkoutsScreenBackground: View {
    var body: some View {
        DeltsBackground()
    }
}
