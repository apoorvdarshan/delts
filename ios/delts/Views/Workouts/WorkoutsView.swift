import SwiftData
import SwiftUI
import UIKit

struct WorkoutsView: View {
    var body: some View {
        NavigationStack {
            ExerciseLibraryBrowserView()
                .background(WorkoutsScreenBackground())
                .navigationTitle("Workouts")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct ExerciseLibraryBrowserView: View {
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @AppStorage("profile_dataset_primary_muscles") private var datasetPrimaryMusclesRaw = ""
    @AppStorage("profile_dataset_raw_equipment") private var datasetRawEquipmentRaw = ""
    @AppStorage("profile_show_only_target_primary_filters") private var showOnlyTargetPrimaryFilters = false
    @AppStorage(RPEScale.storageKey) private var rpeScaleRaw = RPEScale.strength.rawValue
    @State private var searchText = ""
    @State private var selectedSplitGroupTitles: Set<String> = []
    @State private var selectedLevels: Set<String> = []
    @State private var selectedRawEquipment: Set<String> = []
    @State private var selectedPrimaryMuscles: Set<String> = []
    @State private var selectedSecondaryMuscles: Set<String> = []
    @State private var selectedForces: Set<String> = []
    @State private var selectedMechanics: Set<String> = []
    @State private var selectedCategories: Set<String> = []
    @State private var selectedSort: ExerciseLibrarySort = .name
    @State private var dayPlans: [String: WorkoutDayPlan] = WorkoutDayPlanStore.load()
    @State private var startedWorkoutRoute: PlannedWorkoutDetailRoute?

    private let service = ExerciseLibraryService.shared

    private var todayKey: String {
        WorkoutDayPlanStore.key(for: Date())
    }

    private var todayExercises: [PlannedRoutineExercise] {
        dayPlans[todayKey]?.exercises ?? []
    }

    private var rpeScale: RPEScale {
        RPEScale(rawValue: rpeScaleRaw) ?? .strength
    }

    private var selectedWorkoutSplit: WorkoutSplit {
        profiles.first?.workoutSplit ?? .fullBody
    }

    private var splitFilterTitle: String {
        switch selectedWorkoutSplit {
        case .fullBody, .custom:
            return "Body Part"
        default:
            return selectedWorkoutSplit.title
        }
    }

    private var usesBodyPartSplitFilter: Bool {
        selectedWorkoutSplit == .fullBody || selectedWorkoutSplit == .custom
    }

    private var splitGroups: [WorkoutSplitMuscleGroup] {
        let groups = WorkoutSplitMuscleGroup.groups(for: selectedWorkoutSplit)
        guard groups.isEmpty else { return groups }

        let muscles = Set(service.availablePrimaryMuscles + service.availableSecondaryMuscles)
        return muscles.sorted().map { muscle in
            WorkoutSplitMuscleGroup(title: muscle, muscles: [muscle])
        }
    }

    private var selectedSplitGroups: [WorkoutSplitMuscleGroup] {
        splitGroups.filter { selectedSplitGroupTitles.contains($0.title) }
    }

    private var shouldShowPrimaryFilter: Bool {
        !(usesBodyPartSplitFilter && !selectedSplitGroupTitles.isEmpty)
    }

    private var primaryFilterOptions: [String] {
        let baseOptions: [String]
        if selectedSplitGroups.isEmpty {
            baseOptions = service.availablePrimaryMuscles
        } else {
            let allowedMuscles = Set(selectedSplitGroups.flatMap(\.muscles))
            baseOptions = service.availablePrimaryMuscles.filter { allowedMuscles.contains($0) }
        }
        return targetFilteredPrimaryOptions(baseOptions)
    }

    private var profileRawEquipmentOptions: [String] {
        let selectedEquipment = datasetStoredSet(datasetRawEquipmentRaw, allowedValues: service.availableRawEquipment)
        return service.availableRawEquipment.filter { selectedEquipment.contains($0) }
    }

    private var profileTargetPrimaryMuscles: Set<String> {
        datasetStoredSet(datasetPrimaryMusclesRaw, allowedValues: service.availablePrimaryMuscles)
    }

    private var effectivePrimaryMuscleSelection: Set<String> {
        if !selectedPrimaryMuscles.isEmpty {
            return selectedPrimaryMuscles
        }
        guard shouldApplyTargetPrimaryFilter else { return [] }
        return Set(primaryFilterOptions)
    }

    private var shouldApplyTargetPrimaryFilter: Bool {
        shouldShowPrimaryFilter && showOnlyTargetPrimaryFilters
    }

    private var effectiveRawEquipmentSelection: Set<String> {
        if selectedRawEquipment.isEmpty {
            return Set(profileRawEquipmentOptions)
        }
        return selectedRawEquipment
    }

    private var items: [ExerciseLibraryItem] {
        let primaryMuscleSelection = effectivePrimaryMuscleSelection
        if shouldApplyTargetPrimaryFilter && primaryMuscleSelection.isEmpty {
            return []
        }

        let rawEquipmentSelection = effectiveRawEquipmentSelection
        guard !rawEquipmentSelection.isEmpty else { return [] }

        let filtered = service.filtered(
            levels: selectedLevels,
            rawEquipment: rawEquipmentSelection,
            primaryMuscles: primaryMuscleSelection,
            secondaryMuscles: selectedSecondaryMuscles,
            forces: selectedForces,
            mechanics: selectedMechanics,
            categories: selectedCategories,
            sort: selectedSort,
            searchText: searchText
        )
        guard !selectedSplitGroups.isEmpty else { return filtered }
        let selectedMuscles = Set(selectedSplitGroups.flatMap(\.muscles))
        return filtered.filter { item in
            item.primaryMuscles.contains { selectedMuscles.contains($0) } ||
                item.secondaryMuscles.contains { selectedMuscles.contains($0) }
        }
    }

    private var hasActiveFilters: Bool {
        !searchText.isEmpty ||
            !selectedSplitGroupTitles.isEmpty ||
            !selectedLevels.isEmpty ||
            !selectedRawEquipment.isEmpty ||
            !selectedPrimaryMuscles.isEmpty ||
            !selectedSecondaryMuscles.isEmpty ||
            !selectedForces.isEmpty ||
            !selectedMechanics.isEmpty ||
            !selectedCategories.isEmpty ||
            selectedSort != .name
    }

    private var filterStateSnapshot: ExerciseFilterState {
        ExerciseFilterState(
            searchText: searchText,
            splitGroups: selectedSplitGroupTitles,
            levels: selectedLevels,
            rawEquipment: selectedRawEquipment,
            primaryMuscles: selectedPrimaryMuscles,
            secondaryMuscles: selectedSecondaryMuscles,
            forces: selectedForces,
            mechanics: selectedMechanics,
            categories: selectedCategories,
            sort: selectedSort
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                filters
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 18)

                if items.isEmpty {
                    ContentUnavailableView(
                        "No exercises match",
                        systemImage: "line.3.horizontal.decrease",
                        description: Text("Reset filters or search a different body part, machine, or exercise.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .padding(.horizontal, 20)
                } else {
                    ResultsHeader(
                        count: items.count,
                        noun: "exercise",
                        subtitle: selectedSort.title,
                        selectedSort: $selectedSort,
                        canReset: hasActiveFilters,
                        onReset: {
                            withAnimation(.snappy) {
                                resetFilters()
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)

                    ForEach(items) { item in
                        NavigationLink {
                            ExerciseLibraryDetailView(
                                item: item,
                                plannedExercise: todayExercise(for: item),
                                dayExercises: todayExercises,
                                rpeScale: rpeScale,
                                allowsSetEditing: false,
                                startToday: {
                                    startOrOpenTodayWorkout(item)
                                }
                            )
                        } label: {
                            ExerciseLibraryRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)

                        if item.id != items.last?.id {
                            Divider()
                                .overlay(Color.deltsHairline.opacity(0.28))
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
        .navigationDestination(item: $startedWorkoutRoute) { route in
            if let exercise = todayExercises.first(where: { $0.id == route.exerciseID }) {
                ExerciseLibraryDetailView(
                    item: detailItem(for: exercise),
                    plannedExercise: exercise,
                    dayExercises: todayExercises,
                    rpeScale: rpeScale,
                    allowsSetEditing: true,
                    updateSets: { sets in
                        updateTodayExercise(exercise.id) { $0.setSetCount(sets) }
                    },
                    updateSetReps: { setIndex, reps in
                        updateTodayExercise(exercise.id) { exercise in
                            exercise.setReps(reps, forSet: setIndex)
                            exercise.syncSetCompletionTimestamp(forSet: setIndex)
                        }
                    },
                    updateSetRPE: { setIndex, rpe in
                        let scale = rpeScale
                        updateTodayExercise(exercise.id) { exercise in
                            let values = exercise.normalizedSetRPE
                            let previous = values.indices.contains(setIndex) ? values[setIndex] : ""
                            exercise.setRPE(scale.sanitizedInput(rpe, previousValue: previous), forSet: setIndex)
                            exercise.syncSetCompletionTimestamp(forSet: setIndex)
                        }
                    },
                    toggleDone: {
                        updateTodayExercise(exercise.id) { $0.setDone(!$0.isDone) }
                    },
                    markDone: {
                        updateTodayExercise(exercise.id) { $0.setDone(true) }
                    },
                    openNext: nextRouteAction(after: exercise.id)
                )
            } else {
                ContentUnavailableView(
                    "Workout removed",
                    systemImage: "trash",
                    description: Text("This workout is no longer in today's list.")
                )
                .deltsScreen()
            }
        }
        .onAppear {
            applyFilterState(ExerciseFilterStateStore.load(key: ExerciseFilterStateStore.workoutsKey))
            dayPlans = WorkoutDayPlanStore.load()
            normalizePrimaryFilterSelection()
            normalizeEquipmentFilterSelection()
        }
        .onChange(of: filterStateSnapshot) { _, state in
            ExerciseFilterStateStore.save(state, key: ExerciseFilterStateStore.workoutsKey)
        }
        .onChange(of: selectedWorkoutSplit) {
            selectedSplitGroupTitles.removeAll()
            normalizePrimaryFilterSelection()
        }
        .onChange(of: selectedSplitGroupTitles) {
            normalizePrimaryFilterSelection()
        }
        .onChange(of: datasetPrimaryMusclesRaw) {
            normalizePrimaryFilterSelection()
        }
        .onChange(of: showOnlyTargetPrimaryFilters) {
            normalizePrimaryFilterSelection()
        }
        .onChange(of: datasetRawEquipmentRaw) {
            normalizeEquipmentFilterSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: WorkoutDayPlanStore.didChangeNotification)) { _ in
            dayPlans = WorkoutDayPlanStore.load()
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 12) {
            WorkoutsSearchPill(searchText: $searchText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    filterMenuPill(
                        title: splitFilterTitle,
                        value: selectionTitle(selectedSplitGroupTitles),
                        systemImage: "square.grid.2x2"
                    ) {
                        menuChoice("All \(splitFilterTitle)", isSelected: selectedSplitGroupTitles.isEmpty) {
                            selectedSplitGroupTitles.removeAll()
                        }
                        ForEach(splitGroups) { group in
                            muscleMenuChoice(group.title, muscles: group.muscles, isSelected: selectedSplitGroupTitles.contains(group.title)) {
                                selectedSplitGroupTitles = toggledSelection(group.title, in: selectedSplitGroupTitles)
                            }
                        }
                    }

                    if shouldShowPrimaryFilter {
                        filterMenuPill(
                            title: "Primary",
                            value: primaryFilterTitle,
                            systemImage: "scope"
                        ) {
                            menuChoice(allPrimaryMenuTitle, isSelected: selectedPrimaryMuscles.isEmpty) {
                                selectedPrimaryMuscles.removeAll()
                            }
                            ForEach(primaryFilterOptions, id: \.self) { muscle in
                                muscleMenuChoice(muscle, muscles: [muscle], isSelected: selectedPrimaryMuscles.contains(muscle)) {
                                    selectedPrimaryMuscles = toggledSelection(muscle, in: selectedPrimaryMuscles)
                                }
                            }
                        }
                    }

                    filterMenuPill(
                        title: "Secondary",
                        value: selectionTitle(selectedSecondaryMuscles),
                        systemImage: "scope"
                    ) {
                        menuChoice("All Secondary", isSelected: selectedSecondaryMuscles.isEmpty) {
                            selectedSecondaryMuscles.removeAll()
                        }
                        ForEach(service.availableSecondaryMuscles, id: \.self) { muscle in
                            muscleMenuChoice(muscle, muscles: [muscle], isSelected: selectedSecondaryMuscles.contains(muscle)) {
                                selectedSecondaryMuscles = toggledSelection(muscle, in: selectedSecondaryMuscles)
                            }
                        }
                    }

                    filterMenuPill(
                        title: "Equipment",
                        value: equipmentFilterTitle,
                        systemImage: "dumbbell.fill"
                    ) {
                        menuChoice(allEquipmentMenuTitle, isSelected: selectedRawEquipment.isEmpty) {
                            selectedRawEquipment.removeAll()
                        }
                        ForEach(profileRawEquipmentOptions, id: \.self) { equipment in
                            menuChoice(equipment, isSelected: selectedRawEquipment.contains(equipment)) {
                                selectedRawEquipment = toggledSelection(equipment, in: selectedRawEquipment)
                            }
                        }
                    }

                    filterMenuPill(
                        title: "Level",
                        value: selectionTitle(selectedLevels),
                        systemImage: "chart.bar.fill"
                    ) {
                        menuChoice("All Levels", isSelected: selectedLevels.isEmpty) { selectedLevels.removeAll() }
                        ForEach(service.availableLevels, id: \.self) { level in
                            menuChoice(level, isSelected: selectedLevels.contains(level)) {
                                selectedLevels = toggledSelection(level, in: selectedLevels)
                            }
                        }
                    }

                    filterMenuPill(
                        title: "Force",
                        value: selectionTitle(selectedForces),
                        systemImage: "arrow.left.arrow.right"
                    ) {
                        menuChoice("All Forces", isSelected: selectedForces.isEmpty) { selectedForces.removeAll() }
                        ForEach(service.availableForces, id: \.self) { force in
                            menuChoice(force, isSelected: selectedForces.contains(force)) {
                                selectedForces = toggledSelection(force, in: selectedForces)
                            }
                        }
                    }

                    filterMenuPill(
                        title: "Mechanic",
                        value: selectionTitle(selectedMechanics),
                        systemImage: "gearshape"
                    ) {
                        menuChoice("All Mechanics", isSelected: selectedMechanics.isEmpty) { selectedMechanics.removeAll() }
                        ForEach(service.availableMechanics, id: \.self) { mechanic in
                            menuChoice(mechanic, isSelected: selectedMechanics.contains(mechanic)) {
                                selectedMechanics = toggledSelection(mechanic, in: selectedMechanics)
                            }
                        }
                    }

                    filterMenuPill(
                        title: "Category",
                        value: categoryFilterTitle,
                        systemImage: "tag"
                    ) {
                        menuChoice("All Categories", isSelected: selectedCategories.isEmpty) { selectedCategories.removeAll() }
                        ForEach(service.availableCategoryCounts) { categoryCount in
                            menuChoice(categoryMenuTitle(categoryCount), isSelected: selectedCategories.contains(categoryCount.category)) {
                                selectedCategories = toggledSelection(categoryCount.category, in: selectedCategories)
                            }
                        }
                    }
                }
                .padding(.vertical, 1)
            }
        }
    }

    private var equipmentFilterTitle: String {
        if selectedRawEquipment.isEmpty {
            return "All \(profileRawEquipmentOptions.count)"
        }
        return selectionTitle(selectedRawEquipment)
    }

    private var primaryFilterTitle: String {
        if selectedPrimaryMuscles.isEmpty {
            return "All \(primaryFilterOptions.count)"
        }
        return selectionTitle(selectedPrimaryMuscles)
    }

    private var allPrimaryMenuTitle: String {
        "All Primary (\(primaryFilterOptions.count))"
    }

    private var allEquipmentMenuTitle: String {
        "All Equipment (\(profileRawEquipmentOptions.count))"
    }

    private var categoryFilterTitle: String {
        selectionTitle(selectedCategories)
    }

    private func categoryMenuTitle(_ categoryCount: ExerciseCategoryCount) -> String {
        categoryCount.category
    }

    private func resetFilters() {
        searchText = ""
        selectedSplitGroupTitles.removeAll()
        selectedLevels.removeAll()
        selectedRawEquipment.removeAll()
        selectedPrimaryMuscles.removeAll()
        selectedSecondaryMuscles.removeAll()
        selectedForces.removeAll()
        selectedMechanics.removeAll()
        selectedCategories.removeAll()
        selectedSort = .name
    }

    private func applyFilterState(_ state: ExerciseFilterState) {
        searchText = state.searchText
        selectedSplitGroupTitles = state.splitGroups
        selectedLevels = state.levels
        selectedRawEquipment = state.rawEquipment
        selectedPrimaryMuscles = state.primaryMuscles
        selectedSecondaryMuscles = state.secondaryMuscles
        selectedForces = state.forces
        selectedMechanics = state.mechanics
        selectedCategories = state.categories
        selectedSort = state.sort
    }

    private func normalizePrimaryFilterSelection() {
        if !shouldShowPrimaryFilter {
            selectedPrimaryMuscles.removeAll()
            return
        }

        let validOptions = Set(primaryFilterOptions)
        guard !validOptions.isEmpty else {
            selectedPrimaryMuscles.removeAll()
            return
        }
        selectedPrimaryMuscles = selectedPrimaryMuscles.intersection(validOptions)
    }

    private func targetFilteredPrimaryOptions(_ options: [String]) -> [String] {
        guard showOnlyTargetPrimaryFilters else { return options }
        let targetMuscles = profileTargetPrimaryMuscles
        return options.filter { targetMuscles.contains($0) }
    }

    private func normalizeEquipmentFilterSelection() {
        let validOptions = Set(profileRawEquipmentOptions)
        selectedRawEquipment = selectedRawEquipment.intersection(validOptions)
    }

    private func datasetStoredSet(_ rawValue: String, allowedValues: [String]) -> Set<String> {
        let allowedValues = Set(allowedValues)
        return Set(rawValue
            .split(separator: "|")
            .map(String.init)
            .filter { allowedValues.contains($0) })
    }

    private func selectionTitle(_ selection: Set<String>) -> String {
        if selection.isEmpty { return "All" }
        if selection.count == 1 { return selection.first ?? "All" }
        return "\(selection.count) selected"
    }

    private func toggledSelection(_ value: String, in selection: Set<String>) -> Set<String> {
        var next = selection
        if next.contains(value) {
            next.remove(value)
        } else {
            next.insert(value)
        }
        return next
    }

    private func todayExercise(for item: ExerciseLibraryItem) -> PlannedRoutineExercise? {
        todayExercises.first { $0.itemID == item.id }
    }

    private func detailItem(for exercise: PlannedRoutineExercise) -> ExerciseLibraryItem {
        service.exercises.first { $0.id == exercise.itemID } ?? ExerciseLibraryItem(
            id: exercise.itemID,
            name: exercise.name,
            rawLevel: exercise.rawLevel,
            category: exercise.category,
            rawEquipment: exercise.rawEquipment,
            primaryMuscles: exercise.primaryMuscles,
            instructions: exercise.instructions
        )
    }

    private func startOrOpenTodayWorkout(_ item: ExerciseLibraryItem) {
        var routeID: UUID?
        updateTodayPlan { plan in
            if let index = plan.exercises.firstIndex(where: { $0.itemID == item.id }) {
                plan.exercises[index].start()
                routeID = plan.exercises[index].id
            } else {
                var exercise = PlannedRoutineExercise(item: item)
                exercise.start()
                plan.exercises.append(exercise)
                routeID = exercise.id
            }
        }
        if let routeID {
            startedWorkoutRoute = PlannedWorkoutDetailRoute(exerciseID: routeID)
        }
    }

    private func updateTodayExercise(_ id: UUID, mutate: (inout PlannedRoutineExercise) -> Void) {
        updateTodayPlan { plan in
            guard let index = plan.exercises.firstIndex(where: { $0.id == id }) else { return }
            mutate(&plan.exercises[index])
        }
    }

    private func updateTodayPlan(_ mutate: (inout WorkoutDayPlan) -> Void) {
        var plan = dayPlans[todayKey] ?? WorkoutDayPlan(dateKey: todayKey)
        mutate(&plan)
        if plan.exercises.isEmpty {
            dayPlans.removeValue(forKey: todayKey)
        } else {
            dayPlans[todayKey] = plan
        }
        WorkoutDayPlanStore.save(dayPlans)
        WorkoutDayPlanStore.notifyChanged()
    }

    private func nextRouteAction(after id: UUID) -> (() -> Void)? {
        guard let index = todayExercises.firstIndex(where: { $0.id == id }),
              todayExercises.indices.contains(index + 1)
        else { return nil }
        let nextID = todayExercises[index + 1].id
        return {
            updateTodayExercise(nextID) { $0.start() }
            startedWorkoutRoute = PlannedWorkoutDetailRoute(exerciseID: nextID)
        }
    }

    private func filterMenuPill<Content: View>(
        title: String,
        value: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            FilterMenuPill(title: title, value: value, systemImage: systemImage)
        }
        .menuActionDismissBehavior(.disabled)
        .deltsPressable()
    }

    private func menuChoice(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if isSelected {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
    }

    private func muscleMenuChoice(
        _ title: String,
        muscles: Set<String>,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            if isSelected {
                Label(title, systemImage: "checkmark")
            } else {
                Label(title, image: MuscleGlyphAsset.name(title: title, muscles: muscles))
            }
        }
    }
}

private struct WorkoutFilterPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.horizontal, 14)
        .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.22), lineWidth: 0.5)
        }
    }
}

private struct WorkoutFilterDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.28))
            .frame(height: 0.5)
            .padding(.leading, 48)
    }
}

private struct WorkoutFilterFieldLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.deltsSecondaryAccent)
                .frame(width: 38, height: 34)

            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }
}

private struct WorkoutFilterRow<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            WorkoutFilterFieldLabel(title: title, systemImage: systemImage)
                .layoutPriority(2)

            Spacer(minLength: 12)

            content
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }
}

private struct WorkoutFilterRowLabel: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        WorkoutFilterRow(title: title, systemImage: systemImage) {
            HStack(spacing: 7) {
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .multilineTextAlignment(.trailing)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
            }
            .frame(minWidth: 72, maxWidth: 178, minHeight: 38, alignment: .trailing)
        }
    }
}

private struct WorkoutsSearchRow: View {
    @Binding var searchText: String

    var body: some View {
        WorkoutFilterRow(title: "Search", systemImage: "magnifyingglass") {
            TextField("Exercise", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.deltsCharcoal)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .frame(minWidth: 120)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }
}

private struct WorkoutsSearchPill: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(searchText.isEmpty ? Color.deltsSecondaryAccent : Color.deltsAccent)

            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.deltsMutedText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
        .deltsLiquidBarSurface(cornerRadius: 22)
    }
}

private struct FilterMenuPill: View {
    let title: String
    let value: String
    let systemImage: String

    private var isDefaultValue: Bool {
        value == "All" || value == "Name"
    }

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isDefaultValue ? Color.deltsSecondaryAccent : Color.deltsAccent)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
                .padding(.leading, 1)
        }
        .padding(.horizontal, 12)
        .frame(minWidth: 112, minHeight: 46, alignment: .leading)
        .background(
            Color.deltsPanel.opacity(isDefaultValue ? 0.30 : 0.46),
            in: RoundedRectangle(cornerRadius: 17, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(
                    (isDefaultValue ? Color.deltsHairline : Color.deltsAccent).opacity(isDefaultValue ? 0.30 : 0.42),
                    lineWidth: 0.5
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

private struct ResultsHeader: View {
    let count: Int
    let noun: String
    let subtitle: String
    @Binding var selectedSort: ExerciseLibrarySort
    let canReset: Bool
    let onReset: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count) \(count == 1 ? noun : "\(noun)s")")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .textCase(nil)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.deltsMutedText)
                    .textCase(nil)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    onReset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(canReset ? Color.deltsInferno : Color.deltsMutedText)
                        .lineLimit(1)
                        .padding(.horizontal, 11)
                        .frame(height: 34)
                        .background((canReset ? Color.deltsInferno : Color.deltsPanel).opacity(canReset ? 0.10 : 0.22), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke((canReset ? Color.deltsInferno : Color.deltsHairline).opacity(canReset ? 0.28 : 0.24), lineWidth: 0.5)
                        }
                }
                .disabled(!canReset)
                .buttonStyle(.plain)
                .deltsPressable()

                Menu {
                    ForEach(ExerciseLibrarySort.allCases) { sort in
                        Button {
                            selectedSort = sort
                        } label: {
                            if selectedSort == sort {
                                Label(sort.title, systemImage: "checkmark")
                            } else {
                                Text(sort.title)
                            }
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(selectedSort == .name ? Color.deltsMutedText : Color.deltsAccent)
                        .lineLimit(1)
                        .padding(.horizontal, 11)
                        .frame(height: 34)
                        .background(Color.deltsPanel.opacity(selectedSort == .name ? 0.30 : 0.46), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke((selectedSort == .name ? Color.deltsHairline : Color.deltsAccent).opacity(0.32), lineWidth: 0.5)
                        }
                }
                .buttonStyle(.plain)
                .deltsPressable()
            }
        }
        .padding(.top, 6)
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
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        LibraryTag(title: item.primaryMusclesTitle, systemImage: "scope", tint: Color.deltsMutedText)
                        LibraryTag(title: item.rawEquipment, systemImage: "dumbbell.fill", tint: Color.deltsMutedText)
                        LibraryTag(title: item.rawLevel, systemImage: "chart.bar.fill", tint: Color.deltsMutedText)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        LibraryTag(title: item.primaryMusclesTitle, systemImage: "scope", tint: Color.deltsMutedText)
                        LibraryTag(title: "\(item.rawEquipment) - \(item.rawLevel)", systemImage: "dumbbell.fill", tint: Color.deltsMutedText)
                    }
                }

                Label(item.databaseMetadataSummary, systemImage: "server.rack")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsSecondaryAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.deltsHairline)
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var thumbnail: some View {
        AnimatedExerciseVisual(
            exerciseName: item.name,
            imagePaths: item.imagePaths,
            height: 104,
            fillsWidth: false,
            allowsDerivedImageLookup: false
        )
        .frame(width: 104, height: 104)
        .background(Color.deltsPanel.opacity(0.32), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.38), lineWidth: 0.5)
        }
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
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)

                Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(Color.deltsMutedText)

                historySummaryStrip
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.deltsHairline)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
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
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                HistorySummaryItem(value: "\(logs.count)", label: logs.count == 1 ? "exercise" : "exercises", systemImage: "figure.strengthtraining.traditional")
                HistorySummaryItem(value: "\(completedSets)/\(totalSets)", label: "sets", systemImage: "checkmark")
                HistorySummaryItem(value: "\(workout.durationMinutes)m", label: "duration", systemImage: "clock")
            }

            VStack(alignment: .leading, spacing: 4) {
                HistorySummaryItem(value: "\(logs.count)", label: logs.count == 1 ? "exercise" : "exercises", systemImage: "figure.strengthtraining.traditional")
                HistorySummaryItem(value: "\(completedSets)/\(totalSets)", label: "sets", systemImage: "checkmark")
                HistorySummaryItem(value: "\(workout.durationMinutes)m", label: "duration", systemImage: "clock")
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.deltsMutedText)
    }
}

private struct WorkoutHistoryGlyph: View {
    let workout: CompletedWorkout

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.deltsSecondaryAccent.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.deltsHairline.opacity(0.32), lineWidth: 0.5)
                }

            if let iconName {
                Image(systemName: iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.deltsSecondaryAccent)
            } else {
                Text(initial)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsSecondaryAccent)
            }
        }
        .frame(width: 56, height: 56)
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
            .minimumScaleFactor(0.78)
            .accessibilityElement(children: .combine)
    }
}

struct ExerciseLibraryDetailView: View {
    let item: ExerciseLibraryItem
    var plannedExercise: PlannedRoutineExercise?
    var dayExercises: [PlannedRoutineExercise] = []
    var rpeScale: RPEScale = .strength
    var allowsSetEditing = false
    var startToday: (() -> Void)?
    var updateSets: ((Int) -> Void)?
    var updateSetReps: ((Int, String) -> Void)?
    var updateSetRPE: ((Int, String) -> Void)?
    var toggleDone: (() -> Void)?
    var markDone: (() -> Void)?
    var openNext: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var isMetricsPresented = false
    @FocusState private var focusedField: PlannedSetFocus?

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width

            VStack(spacing: 0) {
                detailHero(width: screenWidth)

                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 24) {
                        if let plannedExercise {
                            ExerciseDetailSetLogSection(
                                exercise: plannedExercise,
                                rpeScale: rpeScale,
                                allowsEditing: allowsSetEditing,
                                restBeforeSeconds: restBeforeSeconds(for: plannedExercise),
                                updateSets: { updateSets?($0) },
                                updateSetReps: { updateSetReps?($0, $1) },
                                updateSetRPE: { updateSetRPE?($0, $1) },
                                focusedField: $focusedField
                            )
                        }

                        DetailInstructionSection(instructions: item.instructions)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 112)
                    .frame(width: screenWidth, alignment: .leading)
                }
                .scrollIndicators(.hidden)
            }
            .frame(width: screenWidth, alignment: .top)
        }
        .deltsScreen()
        .contentMargins(.bottom, 104, for: .scrollContent)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomActions
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 6)
                .deltsBottomActionBackground()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                    dismissKeyboard()
                }
            }
        }
        .sheet(isPresented: $isMetricsPresented) {
            NavigationStack {
                ScrollView {
                    DetailMetricGrid(item: item)
                        .padding(20)
                        .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
                .deltsScreen()
                .navigationTitle("Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isMetricsPresented = false
                        }
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.deltsAccent)
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func detailHero(width: CGFloat) -> some View {
        AnimatedExerciseVisual(
            exerciseName: item.name,
            imagePaths: item.imagePaths,
            height: 294,
            allowsDerivedImageLookup: false
        )
        .frame(width: width, height: 294)
        .frame(width: width, height: 294, alignment: .bottomLeading)
        .overlay(alignment: .topTrailing) {
            Button {
                isMetricsPresented = true
            } label: {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.deltsAccent)
                    .frame(width: 44, height: 44)
                    .background(Color.deltsBackground.opacity(0.82), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.deltsHairline.opacity(0.42), lineWidth: 0.7)
                    }
            }
            .buttonStyle(.plain)
            .deltsPressable()
            .padding(.top, 14)
            .padding(.trailing, 16)
            .accessibilityLabel("Show exercise details")
        }
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(item.name) exercise visual"))
    }

    @ViewBuilder
    private var bottomActions: some View {
        if let plannedExercise, hasPlannedActions {
            HStack(spacing: 10) {
                DoneToggleButton(isDone: plannedExercise.isDone) {
                    toggleDone?()
                }

                PrimaryButton(
                    title: openNext == nil ? "Done & Close" : "Done & Next",
                    systemImage: openNext == nil ? "checkmark.seal.fill" : "arrow.right"
                ) {
                    markDone?()
                    focusedField = nil
                    dismissKeyboard()
                    if let openNext {
                        openNext()
                    } else {
                        dismiss()
                    }
                }
            }
        } else if let startToday {
            PrimaryButton(title: plannedExercise == nil ? "Start Today" : "Open Today", systemImage: plannedExercise == nil ? "play.fill" : "arrow.up.right") {
                startToday()
            }
        }
    }

    private var hasPlannedActions: Bool {
        allowsSetEditing || toggleDone != nil || markDone != nil || openNext != nil
    }

    private func restBeforeSeconds(for exercise: PlannedRoutineExercise) -> Int? {
        guard let index = dayExercises.firstIndex(where: { $0.id == exercise.id }),
              index > 0
        else { return nil }
        let previous = dayExercises[index - 1]
        let previousReference = previous.workoutEndReference ?? previous.addedAt
        let currentReference = exercise.workoutStartReference ?? exercise.addedAt
        return max(0, Int(currentReference.timeIntervalSince(previousReference)))
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct ExerciseDetailSetLogSection: View {
    let exercise: PlannedRoutineExercise
    let rpeScale: RPEScale
    let allowsEditing: Bool
    let restBeforeSeconds: Int?
    let updateSets: (Int) -> Void
    let updateSetReps: (Int, String) -> Void
    let updateSetRPE: (Int, String) -> Void
    let focusedField: FocusState<PlannedSetFocus?>.Binding

    var body: some View {
        let setReps = exercise.normalizedSetReps
        let setRPE = exercise.normalizedSetRPE

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Sets")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.deltsCharcoal)

                    Text(allowsEditing ? "Reps and RPE" : "Read-only log")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                }

                Spacer(minLength: 8)

                if allowsEditing {
                    Stepper(value: Binding(get: { exercise.sets }, set: updateSets), in: 1...12) {
                        Text("\(exercise.sets) set\(exercise.sets == 1 ? "" : "s")")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.deltsCharcoal)
                            .lineLimit(1)
                    }
                    .fixedSize()
                } else {
                    Text("\(exercise.sets) set\(exercise.sets == 1 ? "" : "s")")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                        .background(Color.deltsCard.opacity(0.42), in: Capsule())
                }
            }

            if let restBeforeSeconds {
                ExerciseDetailTimingBanner(
                    title: "Rest before",
                    value: ActiveWorkoutViewModel.elapsedDisplay(restBeforeSeconds),
                    systemImage: "timer"
                )
            }

            VStack(spacing: 0) {
                ForEach(Array(setReps.indices), id: \.self) { index in
                    if allowsEditing {
                        VStack(alignment: .leading, spacing: 2) {
                            PlannedSetField(
                                exerciseID: exercise.id,
                                setIndex: index,
                                rpeScale: rpeScale,
                                reps: Binding(
                                    get: {
                                        let values = exercise.normalizedSetReps
                                        return values.indices.contains(index) ? values[index] : ""
                                    },
                                    set: { updateSetReps(index, $0) }
                                ),
                                rpe: Binding(
                                    get: {
                                        let values = exercise.normalizedSetRPE
                                        return values.indices.contains(index) ? values[index] : ""
                                    },
                                    set: { updateSetRPE(index, $0) }
                                ),
                                focusedRepsField: focusedField
                            )

                            if let elapsedSeconds = exercise.setElapsedSeconds(forSet: index) {
                                Text(index == 0 ? "Workout time \(ActiveWorkoutViewModel.elapsedDisplay(elapsedSeconds))" : "Rest \(ActiveWorkoutViewModel.elapsedDisplay(elapsedSeconds))")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.deltsMutedText)
                                    .padding(.leading, 64)
                            }
                        }
                    } else {
                        ExerciseDetailReadOnlySetRow(
                            setIndex: index,
                            reps: setReps.indices.contains(index) ? setReps[index] : "",
                            rpe: setRPE.indices.contains(index) ? setRPE[index] : "",
                            elapsedSeconds: exercise.setElapsedSeconds(forSet: index)
                        )
                    }

                    if index < setReps.count - 1 {
                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.5))
                            .padding(.leading, 64)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.deltsPanel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.66), lineWidth: 0.8)
        }
    }
}

private struct ExerciseDetailTimingBanner: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        Label {
            HStack(spacing: 6) {
                Text(title)
                Text(value)
                    .monospacedDigit()
            }
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(Color.deltsAccent)
        .padding(.horizontal, 10)
        .frame(height: 34)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.deltsAccent.opacity(0.12), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.deltsAccent.opacity(0.24), lineWidth: 0.6)
        }
    }
}

private struct ExerciseDetailReadOnlySetRow: View {
    let setIndex: Int
    let reps: String
    let rpe: String
    let elapsedSeconds: Int?

    var body: some View {
        HStack(spacing: 10) {
            Text("Set \(setIndex + 1)")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(Color.deltsMutedText)
                .frame(width: 54, alignment: .leading)

            readOnlyValue(reps.trimmedValue, placeholder: "Reps")
            readOnlyValue(rpe.trimmedValue, placeholder: "RPE")

            if let elapsedSeconds {
                Text(ActiveWorkoutViewModel.elapsedDisplay(elapsedSeconds))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.deltsAccent)
                    .frame(width: 48, alignment: .trailing)
            }
        }
        .padding(.vertical, 9)
    }

    private func readOnlyValue(_ value: String, placeholder: String) -> some View {
        Text(value.isEmpty ? placeholder : value)
            .font(.system(.subheadline, design: .rounded, weight: .bold).monospacedDigit())
            .foregroundStyle(value.isEmpty ? Color.deltsMutedText.opacity(0.72) : Color.deltsCharcoal)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(Color.deltsCard.opacity(0.42), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.28), lineWidth: 0.6)
            }
    }
}

private extension String {
    var trimmedValue: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct DetailInstructionSection: View {
    let instructions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Instructions", systemImage: "list.number")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.deltsOnAccent)
                            .frame(width: 24, height: 24)
                            .background(Color.deltsAccent, in: Circle())

                        Text(instruction)
                            .font(.body)
                            .foregroundStyle(Color.deltsMutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct DetailMetricGrid: View {
    let item: ExerciseLibraryItem

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                DetailMetric(title: "Level", value: item.rawLevel, systemImage: "chart.bar.fill")
                DetailMetric(title: "Category", value: item.category, systemImage: "tag")
            }

            HStack(spacing: 8) {
                DetailMetric(title: "Force", value: item.force, systemImage: "arrow.left.arrow.right")
                DetailMetric(title: "Mechanic", value: item.mechanic, systemImage: "gearshape")
            }

            HStack(spacing: 8) {
                DetailMetric(title: "Primary", value: item.primaryMusclesTitle, systemImage: "scope")
                DetailMetric(title: "Secondary", value: item.secondaryMusclesTitle, systemImage: "scope")
                DetailMetric(title: "Equipment", value: item.rawEquipment, systemImage: "dumbbell.fill")
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
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
            }

            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)
                .minimumScaleFactor(0.76)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.deltsPanel.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.22), lineWidth: 0.5)
        }
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
                            .overlay(Color.deltsHairline.opacity(0.32))
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
                        .foregroundStyle(Color.deltsCharcoal)
                        .lineLimit(3)
                        .minimumScaleFactor(0.76)

                    Text(workout.date.formatted(date: .complete, time: .shortened))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.deltsSecondaryAccent)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(workout.planSummary)
                .font(.body)
                .foregroundStyle(Color.deltsMutedText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 0) {
                WorkoutSummaryMetric(value: "\(workout.exerciseLogs.count)", title: "Exercises", systemImage: "figure.strengthtraining.traditional")
                Divider().frame(height: 42).overlay(Color.deltsHairline.opacity(0.34))
                WorkoutSummaryMetric(value: "\(completedSets)/\(totalSets)", title: "Sets", systemImage: "checkmark")
                Divider().frame(height: 42).overlay(Color.deltsHairline.opacity(0.34))
                WorkoutSummaryMetric(value: "\(workout.durationMinutes)m", title: "Duration", systemImage: "clock")
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
                        .foregroundStyle(Color.deltsCharcoal)
                        .lineLimit(2)
                        .minimumScaleFactor(0.84)

                    Text("\(exercise.targetMuscle) - \(exercise.equipment)")
                        .font(.caption)
                        .foregroundStyle(Color.deltsMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 12)

                Label("\(completedSets)/\(exercise.sets.count)", systemImage: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsSecondaryAccent)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .background(Color.deltsSecondaryAccent.opacity(0.12), in: Capsule())
            }

            VStack(spacing: 0) {
                ForEach(exercise.sets) { set in
                    CompletedSetLogRow(set: set)

                    if set.id != exercise.sets.last?.id {
                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.28))
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
            Image(systemName: set.completed ? "checkmark" : "minus")
                .foregroundStyle(set.completed ? Color.deltsAccent : Color.deltsMutedText)
                .accessibilityHidden(true)

            Text("Set \(set.setNumber)")
                .foregroundStyle(Color.deltsCharcoal)

            Spacer()

            Text(weightRepText)
                .foregroundStyle(Color.deltsMutedText)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .font(.subheadline)
        .padding(.vertical, 10)
    }

    private var weightRepText: String {
        let weight = set.weight.isEmpty ? "--" : set.weight
        let reps = set.reps.isEmpty ? "--" : set.reps
        guard let rpe = set.rpe?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rpe.isEmpty
        else {
            return "\(weight) x \(reps)"
        }

        return "\(weight) x \(reps) | RPE \(rpe)"
    }
}

private struct WorkoutSummaryMetric: View {
    let value: String
    let title: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 24, height: 24)

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
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
