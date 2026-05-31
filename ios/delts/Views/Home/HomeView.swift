import SwiftUI

struct HomeView: View {
    @State private var dayPlans: [String: WorkoutDayPlan] = WorkoutDayPlanStore.load()
    @State private var selectedDate: Date = .now
    @State private var exerciseSearch = ""
    @State private var isWorkoutPickerPresented = false
    @State private var activePlan: WorkoutPlan?

    private let service = ExerciseLibraryService.shared

    private var selectedDateKey: String {
        WorkoutDayPlanStore.key(for: selectedDate)
    }

    private var selectedExercises: [PlannedRoutineExercise] {
        dayPlans[selectedDateKey]?.exercises ?? []
    }

    private var selectedExerciseIDs: Set<String> {
        Set(selectedExercises.map(\.itemID))
    }

    private var selectedSetCount: Int {
        selectedExercises.reduce(0) { $0 + max($1.sets, 1) }
    }

    private var weekDates: [Date] {
        WorkoutDayPlanStore.weekDates(containing: selectedDate)
    }

    private var matchingExercises: [ExerciseLibraryItem] {
        service.filtered(
            level: nil,
            rawEquipment: nil,
            primaryMuscle: nil,
            secondaryMuscle: nil,
            force: nil,
            mechanic: nil,
            category: nil,
            sort: .name,
            searchText: exerciseSearch
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 34) {
                    topActionRow
                    weekStrip
                    workoutHero
                    plannedWorkoutList
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 132)
            }
            .deltsScreen()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                startBar
            }
            .sheet(isPresented: $isWorkoutPickerPresented) {
                WorkoutPickerSheet(
                    searchText: $exerciseSearch,
                    selectedDateTitle: selectedDateTitle,
                    exercises: matchingExercises,
                    selectedExerciseIDs: selectedExerciseIDs,
                    onAdd: addExercise,
                    onDone: {
                        isWorkoutPickerPresented = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $activePlan) { plan in
                NavigationStack {
                    ActiveWorkoutView(plan: plan)
                }
            }
        }
    }

    private var topActionRow: some View {
        HStack {
            Spacer()

            Button {
                openWorkoutPicker()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 34, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.deltsAccent)
                    .frame(width: 72, height: 72)
                    .background(Color.deltsPanel.opacity(0.44), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.deltsHairline.opacity(0.46), lineWidth: 0.5)
                    }
            }
            .deltsPressable()
            .accessibilityLabel("Add workout")
        }
        .frame(height: 84)
    }

    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                WeekWorkoutDayTile(
                    date: date,
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                    isToday: Calendar.current.isDateInToday(date),
                    workoutCount: workoutCount(for: date)
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.snappy(duration: 0.26)) {
                        selectedDate = date
                    }
                }
            }
        }
        .animation(.snappy(duration: 0.24), value: selectedDate)
    }

    private var workoutHero: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("\(selectedExercises.count)")
                    .font(.system(size: 88, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.deltsAccent)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: selectedExercises.count)

                Text("workout\(selectedExercises.count == 1 ? "" : "s") planned")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
            }
            .frame(maxWidth: .infinity)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.deltsAccent.opacity(0.12))
                        .frame(height: 10)

                    Capsule()
                        .fill(Color.deltsAccent)
                        .frame(
                            width: progressWidth(totalWidth: geometry.size.width),
                            height: 10
                        )
                        .shadow(color: Color.deltsAccent.opacity(0.22), radius: 8, y: 3)
                        .animation(.spring(response: 0.65, dampingFraction: 0.82), value: selectedSetCount)
                }
            }
            .frame(height: 10)

            HStack(spacing: 16) {
                PlannerMetric(label: "Day", value: selectedDateShortTitle)
                PlannerMetric(label: "Sets", value: "\(selectedSetCount)")
                PlannerMetric(label: "Library", value: "\(service.exercises.count)")
            }
        }
    }

    private var plannedWorkoutList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDateTitle)
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.deltsCharcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("Dataset workouts for this day")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                }

                Spacer(minLength: 12)

                Text("\(selectedSetCount) set\(selectedSetCount == 1 ? "" : "s")")
                    .font(.subheadline.monospacedDigit().weight(.heavy))
                    .foregroundStyle(Color.deltsAccent)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Color.deltsAccent.opacity(0.12), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color.deltsAccent.opacity(0.28), lineWidth: 0.5)
                    }
            }

            if selectedExercises.isEmpty {
                EmptyRoutineCard(openPicker: openWorkoutPicker)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(selectedExercises) { exercise in
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
    }

    private var startBar: some View {
        VStack(spacing: 8) {
            PrimaryButton(
                title: selectedExercises.isEmpty ? "Add Workout" : "Start \(selectedDateShortTitle)",
                systemImage: selectedExercises.isEmpty ? "plus" : "play.fill"
            ) {
                if selectedExercises.isEmpty {
                    openWorkoutPicker()
                    return
                }

                activePlan = makePlan(
                    title: "\(selectedDateShortTitle) Workout",
                    summary: "\(selectedDateTitle) planned workout",
                    bodyPart: selectedExercises.first?.primaryMuscles.first ?? "Full Body",
                    exercises: selectedExercises
                )
            }

            Text("\(selectedExercises.count) workout\(selectedExercises.count == 1 ? "" : "s") - \(selectedSetCount) planned set\(selectedSetCount == 1 ? "" : "s")")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .deltsBottomActionBackground()
    }

    private var selectedDateTitle: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        }
        if Calendar.current.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        }
        if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        }
        return selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private var selectedDateShortTitle: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        }
        return selectedDate.formatted(.dateTime.weekday(.abbreviated))
    }

    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        guard selectedSetCount > 0 else { return 0 }
        let progress = min(Double(selectedSetCount) / 24.0, 1.0)
        return max(12, totalWidth * progress)
    }

    private func workoutCount(for date: Date) -> Int {
        dayPlans[WorkoutDayPlanStore.key(for: date)]?.exercises.count ?? 0
    }

    private func openWorkoutPicker() {
        exerciseSearch = ""
        isWorkoutPickerPresented = true
    }

    private func addExercise(_ item: ExerciseLibraryItem) {
        updateSelectedPlan { plan in
            guard !plan.exercises.contains(where: { $0.itemID == item.id }) else { return }
            plan.exercises.append(PlannedRoutineExercise(item: item))
        }
    }

    private func removeExercise(_ id: UUID) {
        updateSelectedPlan { plan in
            plan.exercises.removeAll { $0.id == id }
        }
    }

    private func updateExercise(_ id: UUID, mutate: (inout PlannedRoutineExercise) -> Void) {
        updateSelectedPlan { plan in
            guard let index = plan.exercises.firstIndex(where: { $0.id == id }) else { return }
            mutate(&plan.exercises[index])
        }
    }

    private func updateSelectedPlan(_ mutate: (inout WorkoutDayPlan) -> Void) {
        var plan = dayPlans[selectedDateKey] ?? WorkoutDayPlan(dateKey: selectedDateKey)
        mutate(&plan)
        if plan.exercises.isEmpty {
            dayPlans.removeValue(forKey: selectedDateKey)
        } else {
            dayPlans[selectedDateKey] = plan
        }
        WorkoutDayPlanStore.save(dayPlans)
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

private struct WorkoutDayPlan: Codable, Identifiable, Hashable {
    var dateKey: String
    var exercises: [PlannedRoutineExercise] = []

    var id: String { dateKey }
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

private enum WorkoutDayPlanStore {
    private static let key = "delts.dailyWorkoutPlans.v1"

    static func key(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    static func weekDates(containing date: Date) -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let daysBack = (weekday - calendar.firstWeekday + 7) % 7
        let startOfWeek = calendar.date(byAdding: .day, value: -daysBack, to: startOfDay) ?? startOfDay
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }

    static func load() -> [String: WorkoutDayPlan] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let plans = try? JSONDecoder().decode([String: WorkoutDayPlan].self, from: data)
        else {
            return [:]
        }
        return plans
    }

    static func save(_ plans: [String: WorkoutDayPlan]) {
        guard let data = try? JSONEncoder().encode(plans) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

private struct WeekWorkoutDayTile: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let workoutCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsMutedText.opacity(0.72))

                Text(date.formatted(.dateTime.day()))
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(isSelected ? Color.deltsOnAccent : (isToday ? Color.deltsAccent : Color.deltsCharcoal))
                    .frame(width: 44, height: 44)
                    .background {
                        if isSelected {
                            Circle()
                                .fill(Color.deltsAccent)
                                .shadow(color: Color.deltsAccent.opacity(0.30), radius: 10, y: 4)
                        } else if isToday {
                            Circle()
                                .strokeBorder(Color.deltsAccent.opacity(0.42), lineWidth: 1.5)
                        }
                    }

                Capsule()
                    .fill(workoutCount > 0 ? Color.deltsAccent : Color.clear)
                    .frame(width: workoutCount > 0 ? 18 : 6, height: 4)
            }
            .frame(maxWidth: .infinity)
        }
        .deltsPressable()
        .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
        .accessibilityValue("\(workoutCount) workouts")
    }
}

private struct PlannerMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.monospacedDigit().weight(.heavy))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EmptyRoutineCard: View {
    let openPicker: () -> Void

    var body: some View {
        Button(action: openPicker) {
            HStack(spacing: 14) {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
                    .frame(width: 48, height: 48)
                    .background(Color.deltsAccent.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("No workouts added")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.deltsCharcoal)

                    Text("Tap to add dataset workouts to this day.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.deltsPanel.opacity(0.20), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
            }
        }
        .deltsPressable()
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
                    height: 64,
                    fillsWidth: false,
                    allowsDerivedImageLookup: false
                )
                .frame(width: 64, height: 64)

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

private struct WorkoutPickerSheet: View {
    @Binding var searchText: String
    let selectedDateTitle: String
    let exercises: [ExerciseLibraryItem]
    let selectedExerciseIDs: Set<String>
    let onAdd: (ExerciseLibraryItem) -> Void
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    pickerHeader
                    searchField

                    if exercises.isEmpty {
                        Text("No dataset workouts found.")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.deltsMutedText)
                            .padding(.top, 18)
                    } else {
                        ForEach(exercises.prefix(120)) { item in
                            WorkoutPickerRow(
                                item: item,
                                isSelected: selectedExerciseIDs.contains(item.id)
                            ) {
                                onAdd(item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .deltsScreen()
            .navigationTitle("Add Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.deltsAccent)
                }
            }
        }
    }

    private var pickerHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(selectedDateTitle)
                .font(.caption.weight(.heavy))
                .textCase(.uppercase)
                .foregroundStyle(Color.deltsAccent)

            Text("Pick dataset workouts")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)

            TextField("Search workouts", text: $searchText)
                .textFieldStyle(.plain)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText)
                }
                .deltsPressable()
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(Color.deltsPanel.opacity(0.26), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.32), lineWidth: 0.5)
        }
    }
}

private struct WorkoutPickerRow: View {
    let item: ExerciseLibraryItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AnimatedExerciseVisual(
                    exerciseName: item.name,
                    imagePaths: item.imagePaths,
                    height: 68,
                    fillsWidth: false,
                    allowsDerivedImageLookup: false
                )
                .frame(width: 78, height: 68)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.deltsCharcoal)
                        .lineLimit(2)

                    Text("\(item.primaryMusclesTitle) - \(item.rawEquipment)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsMutedText)
            }
            .padding(12)
            .background(Color.deltsPanel.opacity(isSelected ? 0.28 : 0.18), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.deltsAccent.opacity(0.42) : Color.deltsHairline.opacity(0.26), lineWidth: 0.5)
            }
        }
        .deltsPressable()
    }
}
