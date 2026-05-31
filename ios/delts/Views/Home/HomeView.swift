import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @State private var dayPlans: [String: WorkoutDayPlan] = WorkoutDayPlanStore.load()
    @State private var selectedDate: Date = .now
    @State private var exerciseSearch = ""
    @State private var isWorkoutPickerPresented = false
    @State private var workoutPickerContext = WorkoutPickerContext.all
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

    private var selectedWorkoutSplit: WorkoutSplit {
        profiles.first?.workoutSplit ?? .pushPullLegs
    }

    private var addWorkoutContexts: [WorkoutPickerContext] {
        let groups = WorkoutSplitMuscleGroup.groups(for: selectedWorkoutSplit)
        guard !groups.isEmpty else { return [.all] }
        return groups.map { group in
            WorkoutPickerContext(title: group.title, muscles: group.muscles)
        }
    }

    private var matchingExercises: [ExerciseLibraryItem] {
        let filtered = service.filtered(
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
        guard !workoutPickerContext.muscles.isEmpty else { return filtered }
        return filtered.filter { item in
            item.primaryMuscles.contains { workoutPickerContext.muscles.contains($0) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    WorkoutWeekStrip(
                        selectedDate: $selectedDate,
                        workoutCountForDate: workoutCount
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                Section {
                    StartWorkoutHero(
                        workoutCount: selectedExercises.count,
                        setCount: selectedSetCount,
                        libraryCount: service.exercises.count
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                    if selectedExercises.isEmpty {
                        EmptyRoutineRow(splitTitle: selectedWorkoutSplit.title)
                            .listRowBackground(Color.deltsPanel.opacity(0.22))
                    } else {
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
                            .listRowBackground(Color.deltsPanel.opacity(0.20))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    removeExercise(exercise.id)
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                        }
                    }
                } header: {
                    HStack(alignment: .center) {
                        Label(selectedDateTitle, systemImage: "dumbbell.fill")
                        Spacer()
                        Text("\(selectedSetCount) set\(selectedSetCount == 1 ? "" : "s")")
                            .font(.caption.weight(.bold))
                    }
                    .textCase(nil)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.deltsBackground)
            .animation(.snappy, value: selectedDate)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section(selectedWorkoutSplit.title) {
                            ForEach(addWorkoutContexts) { context in
                                Button {
                                    openWorkoutPicker(context)
                                } label: {
                                    Label(context.title, systemImage: context.systemImage)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .font(.title2.weight(.semibold))
                    .tint(Color.deltsAccent)
                    .accessibilityLabel("Add workout")
                }
            }
            .safeAreaInset(edge: .bottom) {
                startBar
            }
            .sheet(isPresented: $isWorkoutPickerPresented) {
                WorkoutPickerSheet(
                    searchText: $exerciseSearch,
                    selectedDateTitle: selectedDateTitle,
                    pickerTitle: workoutPickerContext.title,
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

    private var startBar: some View {
        VStack(spacing: 8) {
            PrimaryButton(
                title: "Start \(selectedDateShortTitle)",
                systemImage: "play.fill"
            ) {
                guard !selectedExercises.isEmpty else { return }

                activePlan = HomeWorkoutPlanFactory.makePlan(
                    title: "\(selectedDateShortTitle) Workout",
                    summary: "\(selectedDateTitle) planned workout",
                    bodyPart: selectedExercises.first?.primaryMuscles.first ?? "Full Body",
                    exercises: selectedExercises
                )
            }
            .disabled(selectedExercises.isEmpty)

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
        Calendar.current.isDateInToday(selectedDate)
            ? "Today"
            : selectedDate.formatted(.dateTime.weekday(.abbreviated))
    }

    private func workoutCount(for date: Date) -> Int {
        dayPlans[WorkoutDayPlanStore.key(for: date)]?.exercises.count ?? 0
    }

    private func openWorkoutPicker(_ context: WorkoutPickerContext) {
        workoutPickerContext = context
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
}
