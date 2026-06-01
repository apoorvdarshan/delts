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
    @AppStorage("delts.workoutPickerSource") private var workoutPickerSourceRaw = WorkoutPickerSource.dataset.rawValue
    @AppStorage("delts.savedExerciseIDs") private var savedExerciseIDsRaw = ""
    @FocusState private var focusedRepsField: PlannedSetFocus?
    @State private var keyboardHeight: CGFloat = 0
    @State private var selectedDetailItem: ExerciseLibraryItem?

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

    private var workoutPickerSourceBinding: Binding<WorkoutPickerSource> {
        Binding(
            get: { workoutPickerSource },
            set: { workoutPickerSourceRaw = $0.rawValue }
        )
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
            workoutPickerSource == .dataset || savedExerciseIDs.contains(item.id)
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
                        Text("\(selectedSetCount) set\(selectedSetCount == 1 ? "" : "s")")
                            .font(.caption.weight(.bold))
                    }
                    .textCase(nil)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.deltsBackground)
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
                        Section(selectedWorkoutSplit.title) {
                            ForEach(addWorkoutContexts) { context in
                                Button {
                                    openWorkoutPicker(context)
                                } label: {
                                    Label(context.title, systemImage: context.systemImage)
                                }
                            }
                            Button {
                                openSavedWorkoutPicker()
                            } label: {
                                Label(WorkoutPickerContext.saved.title, systemImage: WorkoutPickerContext.saved.systemImage)
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
            .sheet(isPresented: $isWorkoutPickerPresented) {
                WorkoutPickerSheet(
                    searchText: $exerciseSearch,
                    source: workoutPickerSourceBinding,
                    pickerTitle: workoutPickerContext.title,
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

    private func workoutCount(for date: Date) -> Int {
        dayPlans[WorkoutDayPlanStore.key(for: date)]?.exercises.count ?? 0
    }

    private func libraryItem(for exercise: PlannedRoutineExercise) -> ExerciseLibraryItem? {
        service.exercises.first { $0.id == exercise.itemID }
    }

    private func openWorkoutPicker(_ context: WorkoutPickerContext) {
        workoutPickerContext = context
        exerciseSearch = ""
        isWorkoutPickerPresented = true
    }

    private func openSavedWorkoutPicker() {
        workoutPickerSourceRaw = WorkoutPickerSource.saved.rawValue
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
