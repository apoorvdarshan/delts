import AudioToolbox
import SwiftData
import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @State private var dayPlans: [String: WorkoutDayPlan] = WorkoutDayPlanStore.load()
    @State private var selectedDate: Date = .now
    @State private var exerciseSearch = ""
    @State private var isWorkoutPickerPresented = false
    @State private var workoutPickerContext = WorkoutPickerContext.all
    @State private var pickerSelectedLevels: Set<String> = []
    @State private var pickerSelectedRawEquipment: Set<String> = []
    @State private var pickerSelectedPrimaryMuscles: Set<String> = []
    @State private var pickerSelectedSecondaryMuscles: Set<String> = []
    @State private var pickerSelectedForces: Set<String> = []
    @State private var pickerSelectedMechanics: Set<String> = []
    @State private var pickerSelectedCategories: Set<String> = []
    @State private var pickerSelectedSort: ExerciseLibrarySort = .name
    @AppStorage("delts.workoutPickerSource") private var workoutPickerSourceRaw = WorkoutPickerSource.dataset.rawValue
    @AppStorage("delts.savedExerciseIDs") private var savedExerciseIDsRaw = ""
    @State private var sessionDate: Date?
    @State private var sessionDateKey: String?
    @State private var sessionStartedAt: Date?
    @State private var sessionElapsedSeconds = 0
    @State private var isOtherDateTimerDialogPresented = false
    @State private var isEmptyWorkoutStartDialogPresented = false
    @State private var isCalorieSummaryPresented = false
    @State private var selectedWorkoutRoute: PlannedWorkoutDetailRoute?
    @State private var isGuidedWorkoutPresented = false
    @FocusState private var focusedField: PlannedSetFocus?
    @AppStorage("profile_dataset_primary_muscles") private var datasetPrimaryMusclesRaw = ""
    @AppStorage("profile_dataset_raw_equipment") private var datasetRawEquipmentRaw = ""
    @AppStorage("profile_show_only_target_primary_filters") private var showOnlyTargetPrimaryFilters = false
    @AppStorage(RPEScale.storageKey) private var rpeScaleRaw = RPEScale.strength.rawValue

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

    private var rpeScale: RPEScale {
        RPEScale(rawValue: rpeScaleRaw) ?? .strength
    }

    private var selectedCompletedSetCount: Int {
        selectedExercises.reduce(0) { total, exercise in
            total + exercise.normalizedSetReps.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        }
    }

    private var selectedRepCount: Int {
        selectedExercises.reduce(0) { total, exercise in
            total + exercise.normalizedSetReps.reduce(0) { repsTotal, value in
                repsTotal + (Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0)
            }
        }
    }

    private var isSessionTimerRunning: Bool {
        isSelectedSessionDate && sessionStartedAt != nil
    }

    private var isSessionTimerPaused: Bool {
        isSelectedSessionDate && sessionStartedAt == nil && sessionDateKey != nil
    }

    private var hasSelectedSessionTimer: Bool {
        isSessionTimerRunning || isSessionTimerPaused
    }

    private var isAnySessionTimerRunning: Bool {
        sessionDateKey != nil
    }

    private var isSelectedSessionDate: Bool {
        sessionDateKey == selectedDateKey
    }

    private var selectedTimerStartedAt: Date? {
        isSelectedSessionDate ? sessionStartedAt : nil
    }

    private var selectedTimerElapsedSeconds: Int {
        isSelectedSessionDate ? sessionElapsedSeconds : 0
    }

    private var selectedWorkoutSplit: WorkoutSplit {
        profiles.first?.workoutSplit ?? .pushPullLegs
    }

    private var addWorkoutContexts: [WorkoutPickerContext] {
        let groups = WorkoutSplitMuscleGroup.groups(for: selectedWorkoutSplit)
        guard !groups.isEmpty else { return datasetMuscleContexts }
        return groups.map { group in
            WorkoutPickerContext(title: group.title, muscles: group.muscles)
        }
    }

    private var datasetMuscleContexts: [WorkoutPickerContext] {
        let muscles = Set(service.availablePrimaryMuscles + service.availableSecondaryMuscles)
        return muscles.sorted().map { muscle in
            WorkoutPickerContext(title: muscle, muscles: [muscle])
        }
    }

    private var savedExerciseIDs: Set<String> {
        Set(savedExerciseIDsRaw.split(separator: "|").map(String.init))
    }

    private var workoutPickerSource: WorkoutPickerSource {
        WorkoutPickerSource(rawValue: workoutPickerSourceRaw) ?? .dataset
    }

    private var isSavedWorkoutPickerContext: Bool {
        workoutPickerContext.id == WorkoutPickerContext.saved.id
    }

    private var activeWorkoutPickerSource: WorkoutPickerSource {
        isSavedWorkoutPickerContext ? .saved : workoutPickerSource
    }

    private var usesBodyPartPickerContexts: Bool {
        selectedWorkoutSplit == .fullBody || selectedWorkoutSplit == .custom
    }

    private var hidesWorkoutPickerPrimaryFilter: Bool {
        usesBodyPartPickerContexts && !workoutPickerContext.muscles.isEmpty
    }

    private var workoutPickerSourceBinding: Binding<WorkoutPickerSource> {
        Binding(
            get: { workoutPickerSource },
            set: { workoutPickerSourceRaw = $0.rawValue }
        )
    }

    private var workoutPickerFilterKey: String {
        ExerciseFilterStateStore.startPickerKey(for: workoutPickerContext.id)
    }

    private var workoutPickerFilterState: ExerciseFilterState {
        ExerciseFilterState(
            searchText: exerciseSearch,
            levels: pickerSelectedLevels,
            rawEquipment: pickerSelectedRawEquipment,
            primaryMuscles: pickerSelectedPrimaryMuscles,
            secondaryMuscles: pickerSelectedSecondaryMuscles,
            forces: pickerSelectedForces,
            mechanics: pickerSelectedMechanics,
            categories: pickerSelectedCategories,
            sort: pickerSelectedSort
        )
    }

    private var profileRawEquipmentOptions: [String] {
        let selectedEquipment = datasetStoredSet(datasetRawEquipmentRaw, allowedValues: service.availableRawEquipment)
        return service.availableRawEquipment.filter { selectedEquipment.contains($0) }
    }

    private var profileTargetPrimaryMuscles: Set<String> {
        datasetStoredSet(datasetPrimaryMusclesRaw, allowedValues: service.availablePrimaryMuscles)
    }

    private var workoutPickerPrimaryFilterOptions: [String] {
        let baseOptions: [String]
        if workoutPickerContext.muscles.isEmpty {
            baseOptions = service.availablePrimaryMuscles
        } else {
            baseOptions = service.availablePrimaryMuscles.filter { workoutPickerContext.muscles.contains($0) }
        }
        guard showOnlyTargetPrimaryFilters else { return baseOptions }
        let targetMuscles = profileTargetPrimaryMuscles
        return baseOptions.filter { targetMuscles.contains($0) }
    }

    private var effectivePickerPrimaryMuscleSelection: Set<String> {
        if !pickerSelectedPrimaryMuscles.isEmpty {
            return pickerSelectedPrimaryMuscles
        }
        guard shouldApplyTargetPrimaryPickerFilter else { return [] }
        return Set(workoutPickerPrimaryFilterOptions)
    }

    private var shouldApplyTargetPrimaryPickerFilter: Bool {
        !hidesWorkoutPickerPrimaryFilter && showOnlyTargetPrimaryFilters
    }

    private var effectivePickerRawEquipmentSelection: Set<String> {
        if pickerSelectedRawEquipment.isEmpty {
            return Set(profileRawEquipmentOptions)
        }
        return pickerSelectedRawEquipment
    }

    private var matchingExercises: [ExerciseLibraryItem] {
        let primaryMuscleSelection = effectivePickerPrimaryMuscleSelection
        if shouldApplyTargetPrimaryPickerFilter && primaryMuscleSelection.isEmpty {
            return []
        }

        let rawEquipmentSelection = effectivePickerRawEquipmentSelection
        guard !rawEquipmentSelection.isEmpty else { return [] }

        let filtered = service.filtered(
            levels: pickerSelectedLevels,
            rawEquipment: rawEquipmentSelection,
            primaryMuscles: primaryMuscleSelection,
            secondaryMuscles: pickerSelectedSecondaryMuscles,
            forces: pickerSelectedForces,
            mechanics: pickerSelectedMechanics,
            categories: pickerSelectedCategories,
            sort: pickerSelectedSort,
            searchText: exerciseSearch
        )
        let splitFiltered: [ExerciseLibraryItem]
        if workoutPickerContext.muscles.isEmpty {
            splitFiltered = filtered
        } else {
            splitFiltered = filtered.filter { item in
                item.primaryMuscles.contains { workoutPickerContext.muscles.contains($0) } ||
                    item.secondaryMuscles.contains { workoutPickerContext.muscles.contains($0) }
            }
        }
        return splitFiltered.filter { item in
            activeWorkoutPickerSource == .dataset || savedExerciseIDs.contains(item.id)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
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
                        setCount: selectedCompletedSetCount,
                        repCount: selectedRepCount,
                        timerStartedAt: selectedTimerStartedAt,
                        timerElapsedSeconds: selectedTimerElapsedSeconds,
                        isTimerRunning: isSessionTimerRunning,
                        isTimerPaused: isSessionTimerPaused,
                        hasTimerSession: hasSelectedSessionTimer,
                        toggleTimer: handleSessionTimerTap,
                        stopTimer: stopSessionTimer,
                        discardTimer: discardSessionTimer,
                        showCalories: {
                            isCalorieSummaryPresented = true
                        }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                Section {
                    if selectedExercises.isEmpty {
                        EmptyRoutineRow(splitTitle: selectedWorkoutSplit.title)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                    } else {
                        ForEach(selectedExercises) { exercise in
                            PlannedExerciseRow(
                                exercise: exercise,
                                rpeScale: rpeScale,
                                openDetail: {
                                    selectedWorkoutRoute = PlannedWorkoutDetailRoute(exerciseID: exercise.id)
                                },
                                updateSets: { sets in
                                    updateExercise(exercise.id) { $0.setSetCount(sets) }
                                },
                                updateSetReps: { setIndex, reps in
                                    updateExercise(exercise.id) { $0.setReps(reps, forSet: setIndex) }
                                },
                                updateSetRPE: { setIndex, rpe in
                                    let scale = rpeScale
                                    updateExercise(exercise.id) { exercise in
                                        let values = exercise.normalizedSetRPE
                                        let previous = values.indices.contains(setIndex) ? values[setIndex] : ""
                                        exercise.setRPE(scale.sanitizedInput(rpe, previousValue: previous), forSet: setIndex)
                                    }
                                },
                                focusedField: $focusedField
                            )
                            .id(exercise.id)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    removeExercise(exercise.id)
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                                .tint(Color(red: 0.58, green: 0.10, blue: 0.08))

                                Button {
                                    toggleSavedExercise(exercise.itemID)
                                } label: {
                                    Label(savedExerciseIDs.contains(exercise.itemID) ? "Unsave" : "Save", systemImage: savedExerciseIDs.contains(exercise.itemID) ? "bookmark.slash.fill" : "bookmark.fill")
                                }
                                .tint(Color(red: 0.18, green: 0.42, blue: 0.16))
                            }
                        }
                    }
                } header: {
                    HStack(alignment: .center) {
                        Label(selectedDateTitle, systemImage: "dumbbell.fill")
                        Spacer()
                        Text("\(selectedExercises.count) workout\(selectedExercises.count == 1 ? "" : "s")")
                            .font(.caption.weight(.bold))
                    }
                    .textCase(nil)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.deltsBackground)
            .listSectionSpacing(8)
            .scrollDismissesKeyboard(.interactively)
            .animation(.snappy, value: selectedDate)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            Button {
                                openSavedWorkoutPicker()
                            } label: {
                                WorkoutPickerContextMenuLabel(context: .saved)
                            }
                            ForEach(addWorkoutContexts) { context in
                                Button {
                                    openWorkoutPicker(context)
                                } label: {
                                    WorkoutPickerContextMenuLabel(context: context)
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                        dismissKeyboard()
                    }
                }
            }
            .navigationDestination(item: $selectedWorkoutRoute) { route in
                plannedWorkoutDetailDestination(route)
            }
            .navigationDestination(isPresented: $isGuidedWorkoutPresented) {
                GuidedWorkoutSessionView(
                    title: selectedDateTitle,
                    exercises: selectedExercises,
                    timerStartedAt: selectedTimerStartedAt,
                    timerElapsedSeconds: selectedTimerElapsedSeconds,
                    rpeScale: rpeScale,
                    updateSets: { exerciseID, sets in
                        updateExercise(exerciseID) { $0.setSetCount(sets) }
                    },
                    updateSetReps: { exerciseID, setIndex, reps in
                        updateExercise(exerciseID) { $0.setReps(reps, forSet: setIndex) }
                    },
                    updateSetRPE: { exerciseID, setIndex, rpe in
                        let scale = rpeScale
                        updateExercise(exerciseID) { exercise in
                            let values = exercise.normalizedSetRPE
                            let previous = values.indices.contains(setIndex) ? values[setIndex] : ""
                            exercise.setRPE(scale.sanitizedInput(rpe, previousValue: previous), forSet: setIndex)
                        }
                    },
                    markDone: { exerciseID, isDone in
                        updateExercise(exerciseID) { $0.isDone = isDone }
                    },
                    onFinish: finishGuidedWorkout
                )
            }
            .confirmationDialog("Timer already running", isPresented: $isOtherDateTimerDialogPresented, titleVisibility: .visible) {
                Button("Go to \(activeSessionDateTitle)") {
                    if let sessionDate {
                        selectedDate = sessionDate
                    }
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Stop or discard the \(activeSessionDateTitle) timer before starting another.")
            }
            .alert("Add workouts first", isPresented: $isEmptyWorkoutStartDialogPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Add at least one workout to \(selectedDateTitle) before starting the timer.")
            }
            .sheet(isPresented: $isCalorieSummaryPresented) {
                HomeCalorieSummarySheet(
                    elapsedSeconds: currentSessionElapsedSeconds,
                    workoutCount: selectedExercises.count,
                    setCount: selectedCompletedSetCount,
                    repCount: selectedRepCount
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isWorkoutPickerPresented) {
                WorkoutPickerSheet(
                    searchText: $exerciseSearch,
                    source: workoutPickerSourceBinding,
                    selectedLevels: $pickerSelectedLevels,
                    selectedRawEquipment: $pickerSelectedRawEquipment,
                    selectedPrimaryMuscles: $pickerSelectedPrimaryMuscles,
                    selectedSecondaryMuscles: $pickerSelectedSecondaryMuscles,
                    selectedForces: $pickerSelectedForces,
                    selectedMechanics: $pickerSelectedMechanics,
                    selectedCategories: $pickerSelectedCategories,
                    selectedSort: $pickerSelectedSort,
                    pickerTitle: workoutPickerContext.title,
                    showsSourcePicker: !isSavedWorkoutPickerContext,
                    primaryFilterMuscles: workoutPickerContext.muscles,
                    hidesPrimaryFilter: hidesWorkoutPickerPrimaryFilter,
                    targetPrimaryMuscles: profileTargetPrimaryMuscles,
                    limitsPrimaryToTargetMuscles: showOnlyTargetPrimaryFilters,
                    rawEquipmentOptions: profileRawEquipmentOptions,
                    exercises: matchingExercises,
                    selectedExerciseIDs: selectedExerciseIDs,
                    savedExerciseIDs: savedExerciseIDs,
                    onToggleSelection: toggleExerciseSelection,
                    onToggleSaved: toggleSavedExercise,
                    onDone: {
                        isWorkoutPickerPresented = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: workoutPickerFilterState) { _, state in
                guard isWorkoutPickerPresented else { return }
                ExerciseFilterStateStore.save(state, key: workoutPickerFilterKey)
            }
            .onChange(of: datasetRawEquipmentRaw) {
                normalizeWorkoutPickerEquipmentFilter()
            }
            .onChange(of: datasetPrimaryMusclesRaw) {
                normalizeWorkoutPickerPrimaryFilter()
            }
            .onChange(of: showOnlyTargetPrimaryFilters) {
                normalizeWorkoutPickerPrimaryFilter()
            }
            .onChange(of: selectedExercises) {
                updateSessionLiveActivityIfNeeded()
            }
            .onReceive(NotificationCenter.default.publisher(for: WorkoutDayPlanStore.didChangeNotification)) { _ in
                dayPlans = WorkoutDayPlanStore.load()
            }
            }
        }
    }

    @ViewBuilder
    private func plannedWorkoutDetailDestination(_ route: PlannedWorkoutDetailRoute) -> some View {
        if let exercise = selectedExercises.first(where: { $0.id == route.exerciseID }) {
            ExerciseLibraryDetailView(
                item: detailItem(for: exercise)
            )
        } else {
            ContentUnavailableView(
                "Workout removed",
                systemImage: "trash",
                description: Text("This workout is no longer in this day.")
            )
            .deltsScreen()
        }
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

    private var currentSessionElapsedSeconds: Int {
        guard let sessionStartedAt else { return sessionElapsedSeconds }
        return sessionElapsedSeconds + max(0, Int(Date().timeIntervalSince(sessionStartedAt)))
    }

    private var activeSessionDateTitle: String {
        guard let sessionDate else { return "active day" }
        if Calendar.current.isDateInToday(sessionDate) {
            return "Today"
        }
        if Calendar.current.isDateInTomorrow(sessionDate) {
            return "Tomorrow"
        }
        if Calendar.current.isDateInYesterday(sessionDate) {
            return "Yesterday"
        }
        return sessionDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func workoutCount(for date: Date) -> Int {
        dayPlans[WorkoutDayPlanStore.key(for: date)]?.exercises.count ?? 0
    }

    private func handleSessionTimerTap() {
        if isSessionTimerRunning {
            playTimerClick()
            pauseSessionTimer()
        } else if isSessionTimerPaused {
            playTimerClick()
            resumeSessionTimer()
        } else if isAnySessionTimerRunning {
            playTimerClick()
            isOtherDateTimerDialogPresented = true
        } else if selectedExercises.isEmpty {
            isEmptyWorkoutStartDialogPresented = true
        } else {
            playTimerClick()
            startSessionTimer()
        }
    }

    private func startSessionTimer() {
        if sessionDateKey != selectedDateKey {
            sessionElapsedSeconds = 0
        }
        sessionDate = selectedDate
        sessionDateKey = selectedDateKey
        let startedAt = Date()
        sessionStartedAt = startedAt
        startSessionLiveActivity(startedAt: startedAt)
    }

    private func pauseSessionTimer() {
        sessionElapsedSeconds = currentSessionElapsedSeconds
        sessionStartedAt = nil
        endSessionLiveActivity()
    }

    private func resumeSessionTimer() {
        let startedAt = Date()
        sessionStartedAt = startedAt
        startSessionLiveActivity(startedAt: startedAt)
    }

    private func stopSessionTimer() {
        playTimerClick()
        saveCompletedHomeWorkout()
        sessionElapsedSeconds = 0
        sessionStartedAt = nil
        sessionDate = nil
        sessionDateKey = nil
        endSessionLiveActivity()
    }

    private func discardSessionTimer() {
        playTimerClick()
        sessionElapsedSeconds = 0
        sessionDate = nil
        sessionDateKey = nil
        sessionStartedAt = nil
        endSessionLiveActivity()
    }

    private func playTimerClick() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AudioServicesPlaySystemSound(1104)
    }

    private func openGuidedWorkoutIfPossible() {
        guard !selectedExercises.isEmpty else { return }
        isGuidedWorkoutPresented = true
    }

    private func finishGuidedWorkout() {
        isGuidedWorkoutPresented = false
    }

    private func saveCompletedHomeWorkout() {
        guard !selectedExercises.isEmpty else { return }

        let durationSeconds = max(currentSessionElapsedSeconds, selectedTimerElapsedSeconds)
        let logs = selectedExercises.map { exercise in
            let reps = exercise.normalizedSetReps
            let rpe = exercise.normalizedSetRPE
            let sets = (0..<max(exercise.sets, 1)).map { index in
                let repValue = reps.indices.contains(index) ? reps[index] : ""
                let rpeValue = rpe.indices.contains(index) ? rpe[index] : ""
                let trimmedReps = repValue.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedRPE = rpeValue.trimmingCharacters(in: .whitespacesAndNewlines)

                return CompletedSetLog(
                    setNumber: index + 1,
                    completed: exercise.isDone || !trimmedReps.isEmpty || !trimmedRPE.isEmpty,
                    weight: "",
                    reps: trimmedReps,
                    rpe: trimmedRPE.isEmpty ? nil : trimmedRPE
                )
            }

            return CompletedExerciseLog(
                name: exercise.name,
                targetMuscle: exercise.primaryMuscles.first ?? "Unspecified",
                equipment: exercise.rawEquipment,
                sets: sets
            )
        }

        let completedWorkout = CompletedWorkout(
            title: "\(selectedDateTitle) Workout",
            durationMinutes: max(1, Int(ceil(Double(durationSeconds) / 60.0))),
            planSummary: "\(selectedExercises.count) exercise\(selectedExercises.count == 1 ? "" : "s") from Start",
            exerciseLogs: logs
        )
        modelContext.insert(completedWorkout)
        try? modelContext.save()
    }

    private func startSessionLiveActivity(startedAt: Date) {
        guard let sessionDateKey else { return }
        let visibleStartedAt = startedAt.addingTimeInterval(-TimeInterval(sessionElapsedSeconds))
        WorkoutTimerLiveActivityController.shared.start(
            sessionID: sessionDateKey,
            startedAt: visibleStartedAt,
            dayTitle: activeSessionDateTitle,
            setCount: selectedCompletedSetCount,
            workoutCount: selectedExercises.count,
            repCount: selectedRepCount
        )
    }

    private func updateSessionLiveActivityIfNeeded() {
        guard isAnySessionTimerRunning,
              isSelectedSessionDate,
              let sessionDateKey,
              let sessionStartedAt
        else { return }
        let visibleStartedAt = sessionStartedAt.addingTimeInterval(-TimeInterval(sessionElapsedSeconds))
        WorkoutTimerLiveActivityController.shared.update(
            sessionID: sessionDateKey,
            startedAt: visibleStartedAt,
            dayTitle: activeSessionDateTitle,
            setCount: selectedCompletedSetCount,
            workoutCount: selectedExercises.count,
            repCount: selectedRepCount
        )
    }

    private func endSessionLiveActivity() {
        Task {
            await WorkoutTimerLiveActivityController.shared.end()
        }
    }

    private func libraryItem(for exercise: PlannedRoutineExercise) -> ExerciseLibraryItem? {
        service.exercises.first { $0.id == exercise.itemID }
    }

    private func detailItem(for exercise: PlannedRoutineExercise) -> ExerciseLibraryItem {
        libraryItem(for: exercise) ?? ExerciseLibraryItem(
            id: exercise.itemID,
            name: exercise.name,
            rawLevel: exercise.rawLevel,
            category: exercise.category,
            rawEquipment: exercise.rawEquipment,
            primaryMuscles: exercise.primaryMuscles,
            instructions: exercise.instructions
        )
    }

    private func openWorkoutPicker(_ context: WorkoutPickerContext) {
        workoutPickerContext = context
        applyWorkoutPickerFilterState(ExerciseFilterStateStore.load(key: ExerciseFilterStateStore.startPickerKey(for: context.id)))
        isWorkoutPickerPresented = true
    }

    private func openSavedWorkoutPicker() {
        openWorkoutPicker(.saved)
    }

    private func toggleExerciseSelection(_ item: ExerciseLibraryItem) {
        updateSelectedPlan { plan in
            if plan.exercises.contains(where: { $0.itemID == item.id }) {
                plan.exercises.removeAll { $0.itemID == item.id }
            } else {
                plan.exercises.append(PlannedRoutineExercise(item: item))
            }
        }
    }

    private func toggleSavedExercise(_ id: String) {
        var ids = savedExerciseIDs
        if ids.contains(id) {
            ids.remove(id)
        } else {
            ids.insert(id)
        }
        savedExerciseIDsRaw = ids.sorted().joined(separator: "|")
    }

    private func resetWorkoutPickerFilters() {
        applyWorkoutPickerFilterState(ExerciseFilterState())
    }

    private func applyWorkoutPickerFilterState(_ state: ExerciseFilterState) {
        exerciseSearch = state.searchText
        pickerSelectedLevels = singleStoredSelection(state.levels)
        pickerSelectedRawEquipment = singleStoredSelection(state.rawEquipment)
        pickerSelectedPrimaryMuscles = singleStoredSelection(state.primaryMuscles)
        pickerSelectedSecondaryMuscles = singleStoredSelection(state.secondaryMuscles)
        pickerSelectedForces = singleStoredSelection(state.forces)
        pickerSelectedMechanics = singleStoredSelection(state.mechanics)
        pickerSelectedCategories = singleStoredSelection(state.categories)
        pickerSelectedSort = state.sort
        normalizeWorkoutPickerPrimaryFilter()
        normalizeWorkoutPickerEquipmentFilter()
    }

    private func normalizeWorkoutPickerPrimaryFilter() {
        if hidesWorkoutPickerPrimaryFilter {
            pickerSelectedPrimaryMuscles.removeAll()
            return
        }

        let validOptions = Set(workoutPickerPrimaryFilterOptions)
        guard !validOptions.isEmpty else {
            pickerSelectedPrimaryMuscles.removeAll()
            return
        }
        pickerSelectedPrimaryMuscles = singleStoredSelection(pickerSelectedPrimaryMuscles.intersection(validOptions))
    }

    private func normalizeWorkoutPickerEquipmentFilter() {
        let validOptions = Set(profileRawEquipmentOptions)
        pickerSelectedRawEquipment = singleStoredSelection(pickerSelectedRawEquipment.intersection(validOptions))
    }

    private func datasetStoredSet(_ rawValue: String, allowedValues: [String]) -> Set<String> {
        let allowedValues = Set(allowedValues)
        return Set(rawValue
            .split(separator: "|")
            .map(String.init)
            .filter { allowedValues.contains($0) })
    }

    private func singleStoredSelection(_ selection: Set<String>) -> Set<String> {
        guard let value = selection.sorted().first else { return [] }
        return [value]
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
        WorkoutDayPlanStore.notifyChanged()
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

}

private struct WorkoutPickerContextMenuLabel: View {
    let context: WorkoutPickerContext

    private var isSaved: Bool {
        context.id == WorkoutPickerContext.saved.id
    }

    var body: some View {
        if isSaved {
            Label(context.title, systemImage: "bookmark.fill")
        } else {
            Label(context.title, image: MuscleGlyphAsset.name(title: context.title, muscles: context.muscles))
        }
    }
}
