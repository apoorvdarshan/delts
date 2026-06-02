import AudioToolbox
import SwiftData
import SwiftUI
import UIKit

struct HomeView: View {
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
    @FocusState private var focusedRepsField: PlannedSetFocus?
    @State private var sessionDate: Date?
    @State private var sessionDateKey: String?
    @State private var sessionStartedAt: Date?
    @State private var sessionElapsedSeconds = 0
    @State private var isTimerStopDialogPresented = false
    @State private var isOtherDateTimerDialogPresented = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var selectedDetailItem: ExerciseLibraryItem?
    @AppStorage("profile_dataset_primary_muscles") private var datasetPrimaryMusclesRaw = ""
    @AppStorage("profile_dataset_raw_equipment") private var datasetRawEquipmentRaw = ""
    @AppStorage("profile_show_only_target_primary_filters") private var showOnlyTargetPrimaryFilters = false

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

    private var isAnySessionTimerRunning: Bool {
        sessionStartedAt != nil
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
                        toggleTimer: handleSessionTimerTap
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                Section {
                    if selectedExercises.isEmpty {
                        EmptyRoutineRow(splitTitle: selectedWorkoutSplit.title)
                            .listRowBackground(Color.deltsPanel.opacity(0.22))
                    } else {
                        ForEach(selectedExercises) { exercise in
                            PlannedExerciseRow(
                                exercise: exercise,
                                focusedRepsField: $focusedRepsField,
                                updateSets: { sets in
                                    updateExercise(exercise.id) { $0.setSetCount(sets) }
                                },
                                updateSetReps: { setIndex, reps in
                                    updateExercise(exercise.id) { $0.setReps(reps, forSet: setIndex) }
                                },
                                openDetail: {
                                    selectedDetailItem = libraryItem(for: exercise)
                                }
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

                                Button {
                                    toggleSavedExercise(exercise.itemID)
                                } label: {
                                    Label(savedExerciseIDs.contains(exercise.itemID) ? "Unsave" : "Save", systemImage: savedExerciseIDs.contains(exercise.itemID) ? "bookmark.slash.fill" : "bookmark.fill")
                                }
                                .tint(Color.deltsAccent)
                            }
                        }
                    }
                } header: {
                    HStack(alignment: .center) {
                        Label(selectedDateTitle, systemImage: "dumbbell.fill")
                        Spacer()
                        Text("\(selectedCompletedSetCount) set\(selectedCompletedSetCount == 1 ? "" : "s") done")
                            .font(.caption.weight(.bold))
                    }
                    .textCase(nil)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.deltsBackground)
            .listSectionSpacing(8)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedRepsField = nil
                dismissKeyboard()
            }
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
            }
            .navigationDestination(item: $selectedDetailItem) { item in
                ExerciseLibraryDetailView(item: item)
            }
            .confirmationDialog("Workout timer", isPresented: $isTimerStopDialogPresented, titleVisibility: .visible) {
                Button("Stop") {
                    stopSessionTimer()
                }

                Button("Discard", role: .destructive) {
                    discardSessionTimer()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Elapsed \(currentSessionElapsedDisplay)")
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
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                updateKeyboardHeight(from: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if focusedRepsField != nil {
                        HStack {
                            Spacer()
                            Button("Done") {
                                focusedRepsField = nil
                                dismissKeyboard()
                            }
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.deltsAccent)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.deltsPanel.opacity(0.72), in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(Color.deltsHairline.opacity(0.72), lineWidth: 0.8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                    }
                }
                .onChange(of: focusedRepsField) { _, field in
                    guard let field else { return }
                    scrollFocusedExercise(field.exerciseID, with: proxy, delay: 0.18)
                }
                .onChange(of: keyboardHeight) { _, _ in
                    guard let field = focusedRepsField else { return }
                    scrollFocusedExercise(field.exerciseID, with: proxy, delay: 0.05)
                }
            }
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

    private var currentSessionElapsedDisplay: String {
        ActiveWorkoutViewModel.elapsedDisplay(currentSessionElapsedSeconds)
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
        playTimerClick()
        if isSessionTimerRunning {
            isTimerStopDialogPresented = true
        } else if isAnySessionTimerRunning {
            isOtherDateTimerDialogPresented = true
        } else {
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

    private func stopSessionTimer() {
        playTimerClick()
        sessionElapsedSeconds = currentSessionElapsedSeconds
        sessionStartedAt = nil
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

    private func startSessionLiveActivity(startedAt: Date) {
        guard let sessionDateKey else { return }
        WorkoutTimerLiveActivityController.shared.start(
            sessionID: sessionDateKey,
            startedAt: startedAt,
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
        WorkoutTimerLiveActivityController.shared.update(
            sessionID: sessionDateKey,
            startedAt: sessionStartedAt,
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
        pickerSelectedLevels = state.levels
        pickerSelectedRawEquipment = state.rawEquipment
        pickerSelectedPrimaryMuscles = state.primaryMuscles
        pickerSelectedSecondaryMuscles = state.secondaryMuscles
        pickerSelectedForces = state.forces
        pickerSelectedMechanics = state.mechanics
        pickerSelectedCategories = state.categories
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
        pickerSelectedPrimaryMuscles = pickerSelectedPrimaryMuscles.intersection(validOptions)
    }

    private func normalizeWorkoutPickerEquipmentFilter() {
        let validOptions = Set(profileRawEquipmentOptions)
        pickerSelectedRawEquipment = pickerSelectedRawEquipment.intersection(validOptions)
    }

    private func datasetStoredSet(_ rawValue: String, allowedValues: [String]) -> Set<String> {
        let allowedValues = Set(allowedValues)
        return Set(rawValue
            .split(separator: "|")
            .map(String.init)
            .filter { allowedValues.contains($0) })
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

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func scrollFocusedExercise(_ id: UUID, with proxy: ScrollViewProxy, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.snappy) {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let screenHeight = UIScreen.main.bounds.height
        keyboardHeight = max(0, screenHeight - frame.minY)
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
