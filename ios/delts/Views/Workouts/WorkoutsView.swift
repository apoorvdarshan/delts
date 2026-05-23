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
        List {
            Section {
                librarySummary
                    .listRowSeparator(.hidden)
            }

            Section {
                filters
                    .listRowSeparator(.hidden)
            }

            if items.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No exercises match",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Reset filters or search a different body part, machine, or exercise.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 260)
                    .listRowSeparator(.hidden)
                }
            } else {
                Section {
                    ForEach(items) { item in
                        NavigationLink {
                            ExerciseLibraryDetailView(item: item)
                        } label: {
                            ExerciseLibraryRow(item: item)
                        }
                    }
                } header: {
                    ResultsHeader(
                        count: items.count,
                        subtitle: selectedSort.title,
                        trailingTitle: "Offline media"
                    )
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, 104, for: .scrollContent)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
        .navigationDestination(item: $generatedPlan) { plan in
            WorkoutPlanView(plan: plan)
        }
    }

    private var librarySummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free Exercise DB")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text("\(service.exercises.count) offline exercises")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 12)

                Label("Bundled", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsAcidGreen)
            }

            Button {
                generatedPlan = service.makePlan(from: items)
            } label: {
                Label("Build From Top \(min(items.count, 8))", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color.deltsElectricBlue)
            .disabled(items.isEmpty)
        }
        .padding(.vertical, 8)
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Filter")
                    .font(.headline.weight(.semibold))

                Spacer()

                if hasActiveFilters {
                    Button("Reset") {
                        withAnimation(.snappy) {
                            resetFilters()
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    filterMenu(
                        title: "Body",
                        value: selectedMuscleGroup?.title ?? "All",
                        systemImage: "figure.strengthtraining.traditional"
                    ) {
                        Button("All Body Parts") { selectedMuscleGroup = nil }
                        ForEach(MuscleGroup.allCases) { group in
                            Button(group.title) { selectedMuscleGroup = group }
                        }
                    }

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
                        value: selectedEquipment?.title ?? "All",
                        systemImage: "dumbbell.fill"
                    ) {
                        Button("All Equipment") { selectedEquipment = nil }
                        ForEach(Equipment.allCases) { equipment in
                            Button(equipment.title) { selectedEquipment = equipment }
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
                }
                .padding(.trailing, 20)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ExerciseEquipmentFamily.allCases) { family in
                        ExerciseEquipmentFamilyChip(
                            family: family,
                            isSelected: selectedEquipmentFamily == family
                        ) {
                            withAnimation(.snappy) {
                                selectedEquipmentFamily = family
                            }
                        }
                    }
                }
                .padding(.trailing, 20)
            }
        }
        .padding(.vertical, 6)
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
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
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
        List {
            if workouts.isEmpty {
                ContentUnavailableView(
                    "No completed workouts yet",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Generate a plan, start it, then finish to create your first log.")
                )
                .frame(maxWidth: .infinity, minHeight: 360)
                .listRowSeparator(.hidden)
            } else {
                Section {
                    ForEach(workouts) { workout in
                        NavigationLink {
                            CompletedWorkoutDetailView(workout: workout)
                        } label: {
                            CompletedWorkoutRow(workout: workout)
                        }
                    }
                } header: {
                    ResultsHeader(
                        count: workouts.count,
                        subtitle: "Completed",
                        trailingTitle: "Local logs"
                    )
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, 104, for: .scrollContent)
    }
}

private struct ResultsHeader: View {
    let count: Int
    let subtitle: String
    let trailingTitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count) \(count == 1 ? "item" : "items")")
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

private struct ExerciseEquipmentFamilyChip: View {
    let family: ExerciseEquipmentFamily
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        if isSelected {
            Button(action: action) {
                Text(family.title)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(Color.deltsElectricBlue)
        } else {
            Button(action: action) {
                Text(family.title)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.secondary)
        }
    }
}

private struct ExerciseLibraryRow: View {
    let item: ExerciseLibraryItem

    var body: some View {
        HStack(spacing: 14) {
            AnimatedExerciseVisual(
                muscleGroup: item.muscleGroup,
                assetName: item.visualAssetName,
                exerciseName: item.name,
                imagePaths: item.imagePaths,
                equipment: item.equipment,
                height: 84,
                fillsWidth: false
            )
            .frame(width: 88, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Text(item.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)

                Text("\(item.muscleGroup.title) - \(item.equipment.title)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)

                HStack(spacing: 6) {
                    LibraryTag(title: item.level.title, systemImage: "chart.bar.fill", tint: .deltsElectricBlue)
                    LibraryTag(title: item.machineLabel, systemImage: "dumbbell.fill", tint: .deltsInferno)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct CompletedWorkoutRow: View {
    let workout: CompletedWorkout

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.deltsElectricBlue)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(workout.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(workout.exerciseLogs.count) exercises - \(workout.durationMinutes)m")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
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
            VStack(alignment: .leading, spacing: 22) {
                AnimatedExerciseVisual(
                    muscleGroup: item.muscleGroup,
                    assetName: item.visualAssetName,
                    exerciseName: item.name,
                    imagePaths: item.imagePaths,
                    equipment: item.equipment,
                    height: 260
                )
                .accessibilityLabel(Text("\(item.name) exercise visual"))

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)

                    Text("\(item.muscleGroup.title) - \(item.equipment.title) - \(item.machineLabel)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.deltsElectricBlue)

                    Text(item.source)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Divider()

                DetailMetricGrid(item: item, restText: restText)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Form tip")
                        .font(.headline.weight(.semibold))
                    Text(item.formTip)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    activePlan = item.singleExercisePlan()
                } label: {
                    Label("Start Exercise", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color.deltsElectricBlue)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 122)
        }
        .background(WorkoutsScreenBackground())
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $activePlan) { plan in
            ActiveWorkoutView(plan: plan)
        }
    }

    private var restText: String {
        item.restSeconds == 0 ? "--" : "\(item.restSeconds)s"
    }
}

private struct DetailMetricGrid: View {
    let item: ExerciseLibraryItem
    let restText: String

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 22, verticalSpacing: 14) {
            GridRow {
                DetailMetric(title: "Level", value: item.level.title, systemImage: "chart.bar.fill")
                DetailMetric(title: "Goal", value: item.goal.title, systemImage: "target")
            }

            GridRow {
                DetailMetric(title: "Sets", value: "\(item.sets)", systemImage: "number")
                DetailMetric(title: "Reps", value: item.reps, systemImage: "repeat")
            }

            GridRow {
                DetailMetric(title: "Rest", value: restText, systemImage: "timer")
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
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.deltsElectricBlue)
        }
    }
}

struct CompletedWorkoutDetailView: View {
    let workout: CompletedWorkout

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(workout.title)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.76)

                    Text(workout.date.formatted(date: .complete, time: .shortened))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.deltsElectricBlue)

                    Text(workout.planSummary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
            }

            ForEach(workout.exerciseLogs) { exercise in
                Section {
                    ForEach(exercise.sets) { set in
                        HStack(spacing: 12) {
                            Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(set.completed ? Color.deltsElectricBlue : .secondary)
                                .accessibilityHidden(true)

                            Text("Set \(set.setNumber)")
                                .foregroundStyle(.primary)

                            Spacer()

                            Text(weightRepText(for: set))
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .textCase(nil)
                        Text("\(exercise.targetMuscle) - \(exercise.equipment) - \(exercise.sets.filter(\.completed).count)/\(exercise.sets.count) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                    .padding(.top, 6)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(WorkoutsScreenBackground())
        .contentMargins(.bottom, 104, for: .scrollContent)
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func weightRepText(for set: CompletedSetLog) -> String {
        let weight = set.weight.isEmpty ? "--" : set.weight
        let reps = set.reps.isEmpty ? "--" : set.reps
        return "\(weight) x \(reps)"
    }
}

private struct WorkoutsScreenBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(uiColor: colorScheme == .dark ? .systemBackground : .secondarySystemBackground)
                .ignoresSafeArea()

            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color.deltsElectricBlue.opacity(0.12),
                Color.clear,
                Color.deltsInferno.opacity(0.08)
            ]
        }

        return [
            Color.deltsElectricBlue.opacity(0.08),
            Color.clear,
            Color.deltsInferno.opacity(0.04)
        ]
    }
}
