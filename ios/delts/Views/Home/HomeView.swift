import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @AppStorage("profile_dataset_primary_muscles") private var datasetPrimaryMusclesRaw = ""
    @State private var routineDays: [WeeklyRoutineDay] = WeeklyRoutineStore.load()
    @State private var selectedDayIndex = WeeklyRoutineStore.todayIndex()
    @State private var exerciseSearch = ""
    @State private var activePlan: WorkoutPlan?

    private let service = ExerciseLibraryService.shared

    private var selectedDay: WeeklyRoutineDay {
        routineDays.indices.contains(selectedDayIndex) ? routineDays[selectedDayIndex] : WeeklyRoutineStore.defaultDays[0]
    }

    private var todayIndex: Int {
        WeeklyRoutineStore.todayIndex()
    }

    private var selectedWorkoutSplit: WorkoutSplit {
        profiles.first?.workoutSplit ?? .pushPullLegs
    }

    private var splitGroups: [WorkoutSplitMuscleGroup] {
        WorkoutSplitMuscleGroup.groups(for: selectedWorkoutSplit)
    }

    private var selectedDaySplitGroups: [WorkoutSplitMuscleGroup] {
        splitGroups(for: selectedDay, index: selectedDayIndex)
    }

    private var selectedDayTargetMuscles: [String] {
        targetMuscles(for: selectedDay, index: selectedDayIndex)
    }

    private var selectedDayTitle: String {
        planTitle(for: selectedDay, index: selectedDayIndex)
    }

    private var matchingExercises: [ExerciseLibraryItem] {
        let search = exerciseSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetMuscles = Set(selectedDayTargetMuscles)
        let filtered = service.filtered(
            level: nil,
            rawEquipment: nil,
            primaryMuscle: nil,
            secondaryMuscle: nil,
            force: nil,
            mechanic: nil,
            category: nil,
            sort: .name,
            searchText: search
        )
        guard !targetMuscles.isEmpty else { return filtered }
        return filtered.filter { item in
            item.primaryMuscles.contains { targetMuscles.contains($0) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    startOverview
                    weekRail
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 128)
            }
            .deltsScreen()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Start")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                startBar
            }
            .sheet(item: $activePlan) { plan in
                NavigationStack {
                    ActiveWorkoutView(plan: plan)
                }
            }
        }
    }

    private var startOverview: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Workout Planner")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .textCase(.uppercase)
                .foregroundStyle(Color.deltsAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(height: 48, alignment: .center)

            Spacer(minLength: 8)

            Image(systemName: "calendar.badge.clock")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 48, height: 48)
                .background(Color.deltsAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 2)
    }

    private var weekRail: some View {
        VStack(spacing: 10) {
            ForEach(routineDays.indices, id: \.self) { index in
                let day = routineDays[index]
                let planTitle = planTitle(for: day, index: index)
                let targetMuscles = targetMuscles(for: day, index: index)
                Button {
                    selectedDayIndex = index
                } label: {
                    HStack(spacing: 12) {
                        Text(day.shortName)
                            .font(.headline.weight(.bold))
                            .frame(width: 44, alignment: .leading)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 7) {
                                Text(planTitle)
                                    .font(.subheadline.weight(.bold))
                                    .lineLimit(1)
                                if index == todayIndex {
                                    Text("Today")
                                        .font(.caption2.weight(.heavy))
                                        .textCase(.uppercase)
                                        .foregroundStyle(index == selectedDayIndex ? Color.deltsAccent : Color.deltsAccent)
                                        .padding(.horizontal, 7)
                                        .frame(height: 20)
                                    .background(Color.deltsAccent.opacity(0.12), in: Capsule())
                                }
                            }
                            Text("\(targetMuscles.prefix(4).joined(separator: ", "))\(targetMuscles.count > 4 ? " +" : "") - \(day.exercises.count) workout\(day.exercises.count == 1 ? "" : "s")")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.deltsMutedText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.74)
                        }

                        Spacer(minLength: 8)

                        Image(systemName: index == selectedDayIndex ? "checkmark.circle.fill" : "chevron.right")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(index == selectedDayIndex ? Color.deltsAccent : Color.deltsMutedText)
                    }
                    .foregroundStyle(Color.deltsCharcoal)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                    .background(Color.deltsPanel.opacity(index == selectedDayIndex ? 0.34 : 0.24), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke((index == selectedDayIndex ? Color.deltsAccent : Color.deltsHairline).opacity(index == selectedDayIndex ? 0.48 : 0.34), lineWidth: 0.5)
                    }
                }
                .deltsPressable()

                if index == selectedDayIndex {
                    selectedDayEditor
                        .padding(.top, 2)
                }
            }
        }
    }

    private var selectedDayEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline) {
                    Text(selectedWorkoutSplit.title)
                        .font(.caption.weight(.heavy))
                        .textCase(.uppercase)
                        .foregroundStyle(Color.deltsMutedText)

                    Spacer()

                    Text(selectedDayTitle)
                        .font(.caption.monospacedDigit().weight(.heavy))
                        .foregroundStyle(Color.deltsAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                if splitGroups.isEmpty {
                    primaryMuscleSelector
                } else {
                    splitGroupSelector
                    selectedMuscleSummary
                }
            }

            TextField("Search dataset workouts", text: $exerciseSearch)
                .textFieldStyle(.plain)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.deltsPanel.opacity(0.32), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.5)
                }

            Menu {
                ForEach(matchingExercises.prefix(60)) { item in
                    Button(item.name) {
                        addExercise(item)
                    }
                }
            } label: {
                Label("Add Workout", systemImage: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.deltsPanel.opacity(0.28), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.5)
                    }
            }

            if selectedDay.exercises.isEmpty {
                EmptyRoutineCard()
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(selectedDay.exercises) { exercise in
                        PlannedExerciseRow(
                            exercise: exercise,
                            updateSets: { sets in
                                updateExercise(exercise.id) { $0.sets = sets }
                            },
                            updateReps: { reps in
                                updateExercise(exercise.id) { $0.reps = reps }
                            },
                            remove: {
                                removeExercise(exercise.id)
                            }
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(Color.deltsPanel.opacity(0.16), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
        }
    }

    private var splitGroupSelector: some View {
        StartHorizontalRail {
            ForEach(splitGroups) { group in
                StartOptionButton(
                    title: group.title,
                    systemImage: "square.grid.2x2",
                    isSelected: selectedDaySplitGroups.contains(group)
                ) {
                    toggleSplitGroup(group)
                }
            }
        }
    }

    private var primaryMuscleSelector: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Primary Targets")
                .font(.caption.weight(.heavy))
                .textCase(.uppercase)
                .foregroundStyle(Color.deltsMutedText)

            StartHorizontalRail {
                ForEach(service.availablePrimaryMuscles, id: \.self) { muscle in
                    StartOptionButton(
                        title: muscle,
                        systemImage: "scope",
                        isSelected: selectedDayTargetMuscles.contains(muscle)
                    ) {
                        toggleTargetMuscle(muscle)
                    }
                }
            }
        }
    }

    private var selectedMuscleSummary: some View {
        StartHorizontalRail {
            ForEach(selectedDayTargetMuscles, id: \.self) { muscle in
                Text(muscle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(Color.deltsAccent.opacity(0.12), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color.deltsAccent.opacity(0.24), lineWidth: 0.5)
                    }
            }
        }
    }

    private var startBar: some View {
        VStack(spacing: 8) {
            PrimaryButton(
                title: selectedDay.exercises.isEmpty ? "Add Workout To Start" : "Start \(selectedDay.name)",
                systemImage: "play.fill"
            ) {
                guard !selectedDay.exercises.isEmpty else { return }
                activePlan = makePlan(
                    title: "\(selectedDay.name) \(selectedDayTitle)",
                    summary: "\(selectedDay.name) routine",
                    bodyPart: selectedDayTargetMuscles.first ?? selectedDay.bodyPart,
                    exercises: selectedDay.exercises
                )
            }
            .disabled(selectedDay.exercises.isEmpty)

            Text("\(selectedDay.exercises.reduce(0) { $0 + max($1.sets, 1) }) total set\(selectedDay.exercises.reduce(0) { $0 + max($1.sets, 1) } == 1 ? "" : "s") planned.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .deltsBottomActionBackground()
    }

    private var profilePrimaryMuscles: [String] {
        let allowed = Set(service.availablePrimaryMuscles)
        return datasetPrimaryMusclesRaw
            .split(separator: "|")
            .map(String.init)
            .filter { allowed.contains($0) }
    }

    private func splitGroups(for day: WeeklyRoutineDay, index: Int) -> [WorkoutSplitMuscleGroup] {
        guard !splitGroups.isEmpty else { return [] }
        let validTitles = Set(splitGroups.map(\.title))
        let storedTitles = day.selectedSplitGroups.filter { validTitles.contains($0) }
        let titles = storedTitles.isEmpty ? defaultSplitGroupTitles(for: index) : storedTitles
        return titles.compactMap { title in
            splitGroups.first { $0.title == title }
        }
    }

    private func targetMuscles(for day: WeeklyRoutineDay, index: Int) -> [String] {
        let allowed = Set(service.availablePrimaryMuscles)
        let groups = splitGroups(for: day, index: index)
        if groups.isEmpty {
            let storedMuscles = day.selectedMuscles.filter { allowed.contains($0) }
            if !storedMuscles.isEmpty {
                return orderedMuscles(Set(storedMuscles))
            }
            if !profilePrimaryMuscles.isEmpty {
                return orderedMuscles(Set(profilePrimaryMuscles))
            }
            if day.bodyPart != WeeklyRoutineStore.anyBodyPart, allowed.contains(day.bodyPart) {
                return [day.bodyPart]
            }
            return []
        }

        return orderedMuscles(Set(groups.flatMap(\.muscles)))
    }

    private func planTitle(for day: WeeklyRoutineDay, index: Int) -> String {
        let groups = splitGroups(for: day, index: index)
        if !groups.isEmpty {
            return groups.map(\.title).joined(separator: " + ")
        }

        let muscles = targetMuscles(for: day, index: index)
        if muscles.isEmpty {
            return "Primary Targets"
        }
        return muscles.prefix(3).joined(separator: " + ") + (muscles.count > 3 ? " +" : "")
    }

    private func defaultSplitGroupTitles(for index: Int) -> [String] {
        guard !splitGroups.isEmpty else { return [] }
        if index == 6, let coreGroup = splitGroups.first(where: { isCoreOrAccessory($0.title) }) {
            return [coreGroup.title]
        }

        let trainingGroups = splitGroups.filter { !isCoreOrAccessory($0.title) }
        let cycle = trainingGroups.isEmpty ? splitGroups : trainingGroups
        guard !cycle.isEmpty else { return [] }
        return [cycle[index % cycle.count].title]
    }

    private func isCoreOrAccessory(_ title: String) -> Bool {
        let lowercasedTitle = title.lowercased()
        return lowercasedTitle.contains("core") || lowercasedTitle.contains("accessory")
    }

    private func orderedMuscles(_ muscles: Set<String>) -> [String] {
        service.availablePrimaryMuscles.filter { muscles.contains($0) }
    }

    private func toggleSplitGroup(_ group: WorkoutSplitMuscleGroup) {
        updateSelectedDay { day in
            var titles = Set(splitGroups(for: day, index: selectedDayIndex).map(\.title))
            if titles.contains(group.title) {
                titles.remove(group.title)
            } else {
                titles.insert(group.title)
            }
            day.selectedSplitGroups = splitGroups
                .map(\.title)
                .filter { titles.contains($0) }
            day.bodyPart = planTitle(for: day, index: selectedDayIndex)
        }
    }

    private func toggleTargetMuscle(_ muscle: String) {
        updateSelectedDay { day in
            var muscles = Set(targetMuscles(for: day, index: selectedDayIndex))
            if muscles.contains(muscle) {
                muscles.remove(muscle)
            } else {
                muscles.insert(muscle)
            }
            day.selectedMuscles = orderedMuscles(muscles)
            day.bodyPart = day.selectedMuscles.first ?? WeeklyRoutineStore.anyBodyPart
        }
    }

    private func addExercise(_ item: ExerciseLibraryItem) {
        updateSelectedDay { day in
            day.exercises.append(PlannedRoutineExercise(item: item))
        }
    }

    private func removeExercise(_ id: UUID) {
        updateSelectedDay { day in
            day.exercises.removeAll { $0.id == id }
        }
    }

    private func updateExercise(_ id: UUID, mutate: (inout PlannedRoutineExercise) -> Void) {
        updateSelectedDay { day in
            guard let index = day.exercises.firstIndex(where: { $0.id == id }) else { return }
            mutate(&day.exercises[index])
        }
    }

    private func updateSelectedDay(_ mutate: (inout WeeklyRoutineDay) -> Void) {
        guard routineDays.indices.contains(selectedDayIndex) else { return }
        mutate(&routineDays[selectedDayIndex])
        WeeklyRoutineStore.save(routineDays)
    }

    private func makePlan(title: String, summary: String, bodyPart: String, exercises: [PlannedRoutineExercise]) -> WorkoutPlan {
        WorkoutPlan(
            title: title,
            summary: summary,
            muscleGroup: muscleGroup(for: bodyPart),
            goal: .generalFitness,
            durationMinutes: 0,
            generatedByAI: false,
            exercises: exercises.enumerated().map { index, exercise in
                WorkoutExercise(
                    orderIndex: index,
                    name: exercise.name,
                    targetMuscle: muscleGroup(for: exercise.primaryMuscles.first ?? bodyPart),
                    equipment: equipment(for: exercise.rawEquipment),
                    sets: max(exercise.sets, 1),
                    reps: exercise.reps,
                    restSeconds: 0,
                    formTip: exercise.instructions.first ?? "",
                    difficulty: exercise.rawLevel
                )
            }
        )
    }

    private func muscleGroup(for rawValue: String) -> MuscleGroup {
        let value = rawValue.lowercased()
        if value.contains("chest") { return .chest }
        if value.contains("back") || value.contains("lat") || value.contains("trap") { return .back }
        if value.contains("leg") || value.contains("quad") || value.contains("hamstring") || value.contains("calf") || value.contains("glute") || value.contains("adductor") || value.contains("abductor") { return .legs }
        if value.contains("shoulder") || value.contains("delt") { return .shoulders }
        if value.contains("bicep") || value.contains("tricep") || value.contains("forearm") { return .arms }
        if value.contains("abdominal") || value.contains("core") { return .core }
        return .fullBody
    }

    private func equipment(for rawValue: String) -> Equipment {
        let value = rawValue.lowercased()
        if value.contains("dumbbell") || value.contains("kettlebell") { return .dumbbells }
        if value.contains("barbell") { return .barbell }
        if value.contains("cable") { return .cableMachine }
        if value.contains("smith") { return .smithMachine }
        if value.contains("bench") { return .bench }
        if value.contains("pull") { return .pullUpBar }
        if value.contains("treadmill") { return .treadmill }
        return .bodyweight
    }
}

private struct WeeklyRoutineDay: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var shortName: String
    var bodyPart: String
    var selectedSplitGroups: [String] = []
    var selectedMuscles: [String] = []
    var exercises: [PlannedRoutineExercise] = []

    init(
        id: UUID = UUID(),
        name: String,
        shortName: String,
        bodyPart: String,
        selectedSplitGroups: [String] = [],
        selectedMuscles: [String] = [],
        exercises: [PlannedRoutineExercise] = []
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.bodyPart = bodyPart
        self.selectedSplitGroups = selectedSplitGroups
        self.selectedMuscles = selectedMuscles
        self.exercises = exercises
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        shortName = try container.decode(String.self, forKey: .shortName)
        bodyPart = try container.decode(String.self, forKey: .bodyPart)
        selectedSplitGroups = try container.decodeIfPresent([String].self, forKey: .selectedSplitGroups) ?? []
        selectedMuscles = try container.decodeIfPresent([String].self, forKey: .selectedMuscles) ?? []
        exercises = try container.decodeIfPresent([PlannedRoutineExercise].self, forKey: .exercises) ?? []
    }
}

private struct PlannedRoutineExercise: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var itemID: String
    var name: String
    var primaryMuscles: [String]
    var rawEquipment: String
    var rawLevel: String
    var category: String
    var imagePaths: [String]
    var instructions: [String]
    var sets: Int = 1
    var reps: String = ""

    init(item: ExerciseLibraryItem) {
        self.itemID = item.id
        self.name = item.name
        self.primaryMuscles = item.primaryMuscles
        self.rawEquipment = item.rawEquipment
        self.rawLevel = item.rawLevel
        self.category = item.category
        self.imagePaths = item.imagePaths
        self.instructions = item.instructions
    }
}

private enum WeeklyRoutineStore {
    static let anyBodyPart = "Any"
    private static let key = "delts.weeklyRoutine.v1"

    static let defaultDays: [WeeklyRoutineDay] = [
        WeeklyRoutineDay(name: "Monday", shortName: "Mon", bodyPart: "Chest"),
        WeeklyRoutineDay(name: "Tuesday", shortName: "Tue", bodyPart: "Back"),
        WeeklyRoutineDay(name: "Wednesday", shortName: "Wed", bodyPart: "Legs"),
        WeeklyRoutineDay(name: "Thursday", shortName: "Thu", bodyPart: "Shoulders"),
        WeeklyRoutineDay(name: "Friday", shortName: "Fri", bodyPart: "Arms"),
        WeeklyRoutineDay(name: "Saturday", shortName: "Sat", bodyPart: "Abdominals"),
        WeeklyRoutineDay(name: "Sunday", shortName: "Sun", bodyPart: anyBodyPart)
    ]

    static func todayIndex() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }

    static func load() -> [WeeklyRoutineDay] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let days = try? JSONDecoder().decode([WeeklyRoutineDay].self, from: data),
              days.count == 7
        else {
            return defaultDays
        }
        return days
    }

    static func save(_ days: [WeeklyRoutineDay]) {
        guard let data = try? JSONEncoder().encode(days) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

private struct EmptyRoutineCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 42, height: 42)
                .background(Color.deltsAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text("Add a dataset workout to this day.")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.deltsPanel.opacity(0.24), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.5)
        }
    }
}

private struct PlannedExerciseRow: View {
    let exercise: PlannedRoutineExercise
    let updateSets: (Int) -> Void
    let updateReps: (String) -> Void
    let remove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AnimatedExerciseVisual(
                    exerciseName: exercise.name,
                    imagePaths: exercise.imagePaths,
                    height: 62,
                    fillsWidth: false,
                    allowsDerivedImageLookup: false
                )
                .frame(width: 62, height: 62)

                VStack(alignment: .leading, spacing: 5) {
                    Text(exercise.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.deltsCharcoal)
                        .lineLimit(2)

                    Text("\(exercise.primaryMuscles.joined(separator: ", ")) - \(exercise.rawEquipment) - \(exercise.rawLevel)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 0)

                Button(action: remove) {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.deltsInferno)
                        .frame(width: 36, height: 36)
                }
                .deltsPressable()
            }

            HStack(spacing: 12) {
                Stepper(value: Binding(get: { exercise.sets }, set: updateSets), in: 1...12) {
                    Text("\(exercise.sets) set\(exercise.sets == 1 ? "" : "s")")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                }

                TextField("Reps", text: Binding(get: { exercise.reps }, set: updateReps))
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .multilineTextAlignment(.center)
                    .frame(width: 74, height: 38)
                    .background(Color.deltsPanel.opacity(0.34), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.5)
                    }
            }
        }
        .padding(12)
        .background(Color.deltsPanel.opacity(0.20), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
        }
    }
}

private struct StartOptionButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(isSelected ? Color.deltsOnAccent : Color.deltsCharcoal)
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(isSelected ? Color.deltsAccent : Color.deltsPanel.opacity(0.22), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.deltsHairline.opacity(isSelected ? 0.18 : 0.30), lineWidth: 0.5)
            }
        }
        .deltsPressable()
    }
}

private struct StartHorizontalRail<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                content
            }
            .padding(.horizontal, 1)
        }
    }
}
