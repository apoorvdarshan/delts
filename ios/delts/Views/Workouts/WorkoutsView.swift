import SwiftData
import SwiftUI

struct WorkoutsView: View {
    @Query(sort: \CompletedWorkout.date, order: .reverse) private var workouts: [CompletedWorkout]
    @State private var selectedMode: WorkoutsMode = .library

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    modePicker

                    if selectedMode == .library {
                        ExerciseLibraryBrowserView()
                    } else {
                        if workouts.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 12) {
                                ForEach(workouts) { workout in
                                    NavigationLink {
                                        CompletedWorkoutDetailView(workout: workout)
                                    } label: {
                                        workoutRow(workout)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .deltsScreen()
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout library")
                .font(.largeTitle.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Text("Browse exercises by body part, level, goal, and equipment. History stays one tap away.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.66))
        }
    }

    private var modePicker: some View {
        Picker("Workouts", selection: $selectedMode) {
            ForEach(WorkoutsMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 14) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Color.deltsElectricBlue)
                Text("No completed workouts yet")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Generate a plan, start it, then finish to create your first log.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func workoutRow(_ workout: CompletedWorkout) -> some View {
        GlassCard(padding: 14) {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.deltsElectricBlue)
                    .frame(width: 44, height: 44)
                    .background(Color.deltsElectricBlue.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.56))
                    Text("\(workout.exerciseLogs.count) exercises - \(workout.durationMinutes)m")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            filterPanel

            HStack {
                Text("\(items.count) exercises")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Button("Reset") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        searchText = ""
                        selectedMuscleGroup = nil
                        selectedLevel = nil
                        selectedGoal = nil
                        selectedEquipment = nil
                        selectedEquipmentFamily = .all
                        selectedSort = .bodyPart
                    }
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsElectricBlue)
            }

            if !items.isEmpty {
                PrimaryButton(title: "Build From Top \(min(items.count, 8))", systemImage: "wand.and.stars") {
                    generatedPlan = service.makePlan(from: items)
                }
            }

            if items.isEmpty {
                noResults
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink {
                            ExerciseLibraryDetailView(item: item)
                        } label: {
                            ExerciseLibraryRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationDestination(item: $generatedPlan) { plan in
            WorkoutPlanView(plan: plan)
        }
    }

    private var filterPanel: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.5))
                    TextField("Search exercises, machines, equipment", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white)
                }
                .padding(12)
                .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                equipmentFamilyPicker

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
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
            }
        }
    }

    private var equipmentFamilyPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExerciseEquipmentFamily.allCases) { family in
                    let isSelected = selectedEquipmentFamily == family
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            selectedEquipmentFamily = family
                        }
                    } label: {
                        Text(family.title)
                            .font(.caption.weight(.black))
                            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.7))
                            .lineLimit(1)
                            .padding(.vertical, 9)
                            .padding(.horizontal, 12)
                            .background(
                                isSelected ? Color.deltsElectricBlue.opacity(0.24) : Color.white.opacity(0.06),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.deltsElectricBlue : Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var noResults: some View {
        GlassCard {
            VStack(spacing: 10) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color.deltsInferno)
                Text("No exercises match")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Reset filters or search a different body part or machine.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
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
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.deltsElectricBlue)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(value)
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct ExerciseLibraryRow: View {
    let item: ExerciseLibraryItem

    var body: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 13) {
                AnimatedExerciseVisual(
                    muscleGroup: item.muscleGroup,
                    assetName: item.visualAssetName,
                    exerciseName: item.name,
                    equipment: item.equipment,
                    height: 92
                )
                .frame(width: 116)

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text("\(item.muscleGroup.title) - \(item.equipment.title)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        libraryTag(item.level.title, tint: .deltsElectricBlue)
                        libraryTag(item.machineLabel, tint: .deltsInferno)
                    }
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    private func libraryTag(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.black))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(tint.opacity(0.18), in: Capsule())
    }
}

private struct ExerciseLibraryDetailView: View {
    let item: ExerciseLibraryItem
    @State private var activePlan: WorkoutPlan?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        AnimatedExerciseVisual(
                            muscleGroup: item.muscleGroup,
                            assetName: item.visualAssetName,
                            exerciseName: item.name,
                            equipment: item.equipment,
                            height: 220
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.name)
                                .font(.largeTitle.weight(.black))
                                .foregroundStyle(.white)
                                .lineLimit(3)
                                .minimumScaleFactor(0.68)
                            Text("\(item.muscleGroup.title) - \(item.equipment.title) - \(item.machineLabel)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.deltsElectricBlue)
                        }

                        HStack(spacing: 8) {
                            MetricPill(title: "Level", value: item.level.title, systemImage: "chart.bar.fill")
                            MetricPill(title: "Goal", value: item.goal.title, systemImage: "target", tint: .deltsInferno)
                        }

                        HStack(spacing: 8) {
                            MetricPill(title: "Sets", value: "\(item.sets)", systemImage: "number")
                            MetricPill(title: "Reps", value: item.reps, systemImage: "repeat", tint: .deltsInferno)
                            MetricPill(title: "Rest", value: restText, systemImage: "timer", tint: .white.opacity(0.78))
                        }

                        Text(item.formTip)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)

                        PrimaryButton(title: "Start Exercise", systemImage: "play.fill") {
                            activePlan = item.singleExercisePlan()
                        }
                    }
                }
            }
            .padding(20)
        }
        .deltsScreen()
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

struct CompletedWorkoutDetailView: View {
    let workout: CompletedWorkout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(workout.title)
                            .font(.largeTitle.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                            .minimumScaleFactor(0.72)
                        Text(workout.date.formatted(date: .complete, time: .shortened))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.deltsElectricBlue)
                        Text(workout.planSummary)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ForEach(workout.exerciseLogs) { exercise in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                                    Text("\(exercise.targetMuscle) - \(exercise.equipment)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.58))
                                }
                                Spacer()
                                Text("\(exercise.sets.filter(\.completed).count)/\(exercise.sets.count)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 10)
                                    .background(Color.deltsElectricBlue.opacity(0.18), in: Capsule())
                            }

                            ForEach(exercise.sets) { set in
                                HStack {
                                    Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(set.completed ? Color.deltsElectricBlue : Color.white.opacity(0.35))
                                    Text("Set \(set.setNumber)")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(weightRepText(for: set))
                                        .foregroundStyle(.white.opacity(0.66))
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .deltsScreen()
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func weightRepText(for set: CompletedSetLog) -> String {
        let weight = set.weight.isEmpty ? "--" : set.weight
        let reps = set.reps.isEmpty ? "--" : set.reps
        return "\(weight) x \(reps)"
    }
}
