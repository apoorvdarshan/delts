import SwiftData
import SwiftUI

struct WorkoutsView: View {
    @Query(sort: \CompletedWorkout.date, order: .reverse) private var workouts: [CompletedWorkout]
    @State private var selectedMode: WorkoutsMode = .library

    var body: some View {
        NavigationStack {
            Group {
                switch selectedMode {
                case .library:
                    ExerciseLibraryBrowserView(selectedMode: $selectedMode)
                case .history:
                    WorkoutHistoryListView(workouts: workouts, selectedMode: $selectedMode)
                }
            }
            .background(WorkoutsScreenBackground())
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
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

    var subtitle: String {
        switch self {
        case .library: return "Pick a focus, preview motion, build a session."
        case .history: return "Review completed sessions and logged sets."
        }
    }

    var systemImage: String {
        switch self {
        case .library: return "figure.strengthtraining.traditional"
        case .history: return "clock"
        }
    }
}

private struct WorkoutsModePill: View {
    let title: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(isSelected ? Color.deltsOnAccent : Color.deltsCharcoal)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isSelected ? Color.deltsAccent : Color.deltsPanel.opacity(0.24), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.deltsHairline.opacity(isSelected ? 0.20 : 0.34), lineWidth: 0.5)
            }
            .contentShape(Capsule())
    }
}

private struct WorkoutsModeTabs: View {
    @Binding var selectedMode: WorkoutsMode

    var body: some View {
        HStack(spacing: 10) {
            ForEach(WorkoutsMode.allCases) { mode in
                Button {
                    withAnimation(.snappy) {
                        selectedMode = mode
                    }
                } label: {
                    WorkoutsModePill(
                        title: mode.title,
                        systemImage: mode.systemImage,
                        isSelected: selectedMode == mode
                    )
                }
                .buttonStyle(.plain)
                .deltsPressable()
                .frame(maxWidth: .infinity)
            }
        }
        .padding(4)
        .background(Color.deltsPanel.opacity(0.16), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
        }
    }
}

private struct ExerciseLibraryBrowserView: View {
    @Binding var selectedMode: WorkoutsMode
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var selectedLevel: ExperienceLevel?
    @State private var selectedGoal: FitnessGoal?
    @State private var selectedEquipment: Equipment?
    @State private var selectedEquipmentFamily: ExerciseEquipmentFamily = .all
    @State private var selectedRawEquipment: String?
    @State private var selectedPrimaryMuscle: String?
    @State private var selectedSecondaryMuscle: String?
    @State private var selectedForce: String?
    @State private var selectedMechanic: String?
    @State private var selectedCategory: String?
    @State private var selectedMedia: ExerciseMediaFilter = .all
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
            rawEquipment: selectedRawEquipment,
            primaryMuscle: selectedPrimaryMuscle,
            secondaryMuscle: selectedSecondaryMuscle,
            force: selectedForce,
            mechanic: selectedMechanic,
            category: selectedCategory,
            media: selectedMedia,
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
            selectedRawEquipment != nil ||
            selectedPrimaryMuscle != nil ||
            selectedSecondaryMuscle != nil ||
            selectedForce != nil ||
            selectedMechanic != nil ||
            selectedCategory != nil ||
            selectedMedia != .all ||
            selectedSort != .bodyPart
    }

    private var hasLibrarySelection: Bool {
        !searchText.isEmpty ||
            selectedMuscleGroup != nil ||
            selectedLevel != nil ||
            selectedGoal != nil ||
            selectedEquipment != nil ||
            selectedEquipmentFamily != .all ||
            selectedRawEquipment != nil ||
            selectedPrimaryMuscle != nil ||
            selectedSecondaryMuscle != nil ||
            selectedForce != nil ||
            selectedMechanic != nil ||
            selectedCategory != nil ||
            selectedMedia != .all
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                librarySummary
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 12)

                WorkoutsModeTabs(selectedMode: $selectedMode)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                filters
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)

                if !hasLibrarySelection {
                    WorkoutLibraryFocusChooser { group in
                        withAnimation(.snappy) {
                            selectedMuscleGroup = group
                        }
                    }
                    .padding(.horizontal, 20)
                } else if items.isEmpty {
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
                        trailingTitle: "Offline media",
                        trailingSystemImage: "wifi.slash"
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
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
        .navigationDestination(item: $generatedPlan) { plan in
            WorkoutPlanView(plan: plan)
        }
    }

    private var librarySummary: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(hasLibrarySelection ? "Exercise library" : "Choose a focus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .textCase(.uppercase)

                Text(hasLibrarySelection ? "\(items.count) matching exercises" : "\(service.exercises.count) offline exercises")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(hasLibrarySelection ? "Build from filtered results" : "Select a body part to browse moving demos")
                    .font(.footnote)
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            if hasLibrarySelection {
                Button {
                    generatedPlan = service.makePlan(from: items)
                } label: {
                    Label("Build \(min(items.count, 8))", systemImage: "wand.and.stars")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.deltsOnAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .background(Color.deltsAccent, in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(Color.deltsHairline.opacity(0.28), lineWidth: 0.5)
                        }
                }
                .deltsPressable()
                .disabled(items.isEmpty)
            } else {
                Label("Motion demos", systemImage: "photo.stack")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsSecondaryAccent)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(Color.deltsSecondaryAccent.opacity(0.11), in: Capsule())
            }
        }
        .padding(.vertical, 2)
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    WorkoutsSearchPill(searchText: $searchText)

                    BodyPartFilterChip(
                        title: "All",
                        systemImage: "scope",
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
                .padding(.vertical, 1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    filterMenuPill(
                        title: "Level",
                        value: selectedLevel?.title ?? "All",
                        systemImage: "chart.bar.fill"
                    ) {
                        menuChoice("All Levels", isSelected: selectedLevel == nil) { selectedLevel = nil }
                        ForEach(ExperienceLevel.allCases) { level in
                            menuChoice(level.title, isSelected: selectedLevel == level) { selectedLevel = level }
                        }
                    }

                    filterMenuPill(
                        title: "Goal",
                        value: selectedGoal?.title ?? "All",
                        systemImage: "target"
                    ) {
                        menuChoice("All Goals", isSelected: selectedGoal == nil) { selectedGoal = nil }
                        ForEach(FitnessGoal.profileCases + [.beginnerForm]) { goal in
                            menuChoice(goal.title, isSelected: selectedGoal == goal) { selectedGoal = goal }
                        }
                    }

                    filterMenuPill(
                        title: "Equipment",
                        value: equipmentFilterTitle,
                        systemImage: "dumbbell.fill"
                    ) {
                        menuChoice("All Equipment", isSelected: selectedEquipment == nil && selectedEquipmentFamily == .all && selectedRawEquipment == nil) {
                            selectedEquipment = nil
                            selectedEquipmentFamily = .all
                            selectedRawEquipment = nil
                        }
                        Section("Family") {
                            ForEach(ExerciseEquipmentFamily.allCases.filter { $0 != .all }) { family in
                                menuChoice(family.title, isSelected: selectedEquipment == nil && selectedEquipmentFamily == family) {
                                    selectedEquipment = nil
                                    selectedEquipmentFamily = family
                                    selectedRawEquipment = nil
                                }
                            }
                        }
                        Section("Specific") {
                            ForEach(Equipment.allCases) { equipment in
                                menuChoice(equipment.title, isSelected: selectedEquipment == equipment) {
                                    selectedEquipment = equipment
                                    selectedEquipmentFamily = .all
                                    selectedRawEquipment = nil
                                }
                            }
                        }
                        Section("Database Raw") {
                            ForEach(service.availableRawEquipment, id: \.self) { equipment in
                                menuChoice(equipment, isSelected: selectedRawEquipment == equipment) {
                                    selectedEquipment = nil
                                    selectedEquipmentFamily = .all
                                    selectedRawEquipment = equipment
                                }
                            }
                        }
                    }

                    filterMenuPill(
                        title: "Database",
                        value: databaseFilterTitle,
                        systemImage: "server.rack"
                    ) {
                        menuChoice("All DB Metadata", isSelected: selectedCategory == nil && selectedForce == nil && selectedMechanic == nil && selectedMedia == .all) {
                            selectedCategory = nil
                            selectedForce = nil
                            selectedMechanic = nil
                            selectedMedia = .all
                        }
                        Section("Category") {
                            ForEach(service.availableCategories, id: \.self) { category in
                                menuChoice(category, isSelected: selectedCategory == category) { selectedCategory = category }
                            }
                        }
                        Section("Force") {
                            ForEach(service.availableForces, id: \.self) { force in
                                menuChoice(force, isSelected: selectedForce == force) { selectedForce = force }
                            }
                        }
                        Section("Mechanic") {
                            ForEach(service.availableMechanics, id: \.self) { mechanic in
                                menuChoice(mechanic, isSelected: selectedMechanic == mechanic) { selectedMechanic = mechanic }
                            }
                        }
                        Section("Media") {
                            ForEach(ExerciseMediaFilter.allCases) { media in
                                menuChoice(media.title, isSelected: selectedMedia == media) { selectedMedia = media }
                            }
                        }
                    }

                    filterMenuPill(
                        title: "Muscles",
                        value: rawMuscleFilterTitle,
                        systemImage: "figure.strengthtraining.traditional"
                    ) {
                        menuChoice("All Raw Muscles", isSelected: selectedPrimaryMuscle == nil && selectedSecondaryMuscle == nil) {
                            selectedPrimaryMuscle = nil
                            selectedSecondaryMuscle = nil
                        }
                        Section("Primary") {
                            ForEach(service.availablePrimaryMuscles, id: \.self) { muscle in
                                menuChoice(muscle, isSelected: selectedPrimaryMuscle == muscle) {
                                    selectedPrimaryMuscle = muscle
                                    selectedSecondaryMuscle = nil
                                }
                            }
                        }
                        Section("Secondary") {
                            ForEach(service.availableSecondaryMuscles, id: \.self) { muscle in
                                menuChoice(muscle, isSelected: selectedSecondaryMuscle == muscle) {
                                    selectedPrimaryMuscle = nil
                                    selectedSecondaryMuscle = muscle
                                }
                            }
                        }
                    }

                    filterMenuPill(
                        title: "Sort",
                        value: selectedSort.title,
                        systemImage: "arrow.up.arrow.down"
                    ) {
                        ForEach(ExerciseLibrarySort.allCases) { sort in
                            menuChoice(sort.title, isSelected: selectedSort == sort) { selectedSort = sort }
                        }
                    }

                    if hasActiveFilters {
                        Button {
                            withAnimation(.snappy) {
                                resetFilters()
                            }
                        } label: {
                            FilterResetPill()
                        }
                        .deltsPressable()
                    }
                }
                .padding(.vertical, 1)
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
        if let selectedRawEquipment {
            return selectedRawEquipment
        }
        return "All"
    }

    private var databaseFilterTitle: String {
        if let selectedCategory {
            return selectedCategory
        }
        if let selectedForce {
            return selectedForce
        }
        if let selectedMechanic {
            return selectedMechanic
        }
        if selectedMedia != .all {
            return selectedMedia.title
        }
        return "All"
    }

    private var rawMuscleFilterTitle: String {
        if let selectedPrimaryMuscle {
            return "Primary \(selectedPrimaryMuscle)"
        }
        if let selectedSecondaryMuscle {
            return "Secondary \(selectedSecondaryMuscle)"
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
        selectedRawEquipment = nil
        selectedPrimaryMuscle = nil
        selectedSecondaryMuscle = nil
        selectedForce = nil
        selectedMechanic = nil
        selectedCategory = nil
        selectedMedia = .all
        selectedSort = .bodyPart
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
                .frame(width: 128)
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
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(
            Color.deltsPanel.opacity(searchText.isEmpty ? 0.30 : 0.46),
            in: RoundedRectangle(cornerRadius: 17, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(
                    (searchText.isEmpty ? Color.deltsHairline : Color.deltsAccent).opacity(searchText.isEmpty ? 0.30 : 0.42),
                    lineWidth: 0.5
                )
        }
    }
}

private struct WorkoutFilterResetLabel: View {
    var body: some View {
        WorkoutFilterRow(title: "Reset", systemImage: "arrow.counterclockwise") {
            Text("Clear filters")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.deltsInferno)
                .lineLimit(1)
        }
    }
}

private struct FilterResetPill: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 14, weight: .bold))

            Text("Reset")
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
        }
        .foregroundStyle(Color.deltsInferno)
        .padding(.horizontal, 13)
        .frame(height: 46)
        .background(Color.deltsInferno.opacity(0.10), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color.deltsInferno.opacity(0.30), lineWidth: 0.5)
        }
    }
}

private struct FilterMenuPill: View {
    let title: String
    let value: String
    let systemImage: String

    private var isDefaultValue: Bool {
        value == "All" || value == "Body Part"
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

private struct WorkoutLibraryFocusChooser: View {
    let select: (MuscleGroup) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 156), spacing: 12, alignment: .top)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Body Part")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ForEach(MuscleGroup.allCases) { group in
                    Button {
                        select(group)
                    } label: {
                        VStack(alignment: .leading, spacing: 9) {
                            AnimatedExerciseVisual(
                                muscleGroup: group,
                                height: 102
                            )

                            HStack(spacing: 8) {
                                Image(systemName: group.icon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.deltsAccent)

                                Text(group.title)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(Color.deltsCharcoal)
                                    .lineLimit(1)

                                Spacer(minLength: 0)

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.deltsMutedText)
                            }
                        }
                        .padding(9)
                        .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.deltsHairline.opacity(0.28), lineWidth: 0.5)
                        }
                    }
                    .deltsPressable()
                }
            }
        }
        .padding(.bottom, 18)
    }
}

private struct WorkoutHistoryListView: View {
    let workouts: [CompletedWorkout]
    @Binding var selectedMode: WorkoutsMode

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                historySummary
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 12)

                WorkoutsModeTabs(selectedMode: $selectedMode)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

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
                        trailingTitle: "Local logs",
                        trailingSystemImage: "clock"
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
                                .overlay(Color.deltsHairline.opacity(0.28))
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

    private var historySummary: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Workout history")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .textCase(.uppercase)

                Text("\(workouts.count) completed \(workouts.count == 1 ? "workout" : "workouts")")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)

                Text("Review finished sessions and logged sets.")
                    .font(.footnote)
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            Label("Local logs", systemImage: "clock")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsSecondaryAccent)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background(Color.deltsSecondaryAccent.opacity(0.11), in: Capsule())
        }
        .padding(.vertical, 2)
    }
}

private struct ResultsHeader: View {
    let count: Int
    let noun: String
    let subtitle: String
    let trailingTitle: String
    var trailingSystemImage: String?

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

            Label {
                Text(trailingTitle)
                    .textCase(nil)
            } icon: {
                if let trailingSystemImage {
                    Image(systemName: trailingSystemImage)
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.deltsMutedText)
            .lineLimit(1)
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
        .deltsPressable()
        .foregroundStyle(isSelected ? Color.deltsOnAccent : Color.deltsCharcoal)
        .padding(.horizontal, 13)
        .frame(height: 38)
        .fixedSize(horizontal: true, vertical: false)
        .background(isSelected ? Color.deltsAccent : Color.deltsPanel.opacity(0.46), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.deltsHairline.opacity(isSelected ? 0.22 : 0.46), lineWidth: 0.5)
        }
        .contentShape(Capsule())
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
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
                        LibraryTag(title: item.muscleGroup.title, systemImage: item.muscleGroup.icon, tint: Color.deltsMutedText)
                        LibraryTag(title: item.equipment.title, systemImage: item.equipment.icon, tint: Color.deltsMutedText)
                        LibraryTag(title: item.level.title, systemImage: "chart.bar.fill", tint: Color.deltsMutedText)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        LibraryTag(title: item.muscleGroup.title, systemImage: item.muscleGroup.icon, tint: Color.deltsMutedText)
                        LibraryTag(title: "\(item.equipment.title) - \(item.level.title)", systemImage: item.equipment.icon, tint: Color.deltsMutedText)
                    }
                }

                Label(rowMetadata, systemImage: item.imagePaths.count > 1 ? "photo.stack" : "photo")
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
            muscleGroup: item.muscleGroup,
            assetName: item.visualAssetName,
            exerciseName: item.name,
            imagePaths: item.imagePaths,
            equipment: item.equipment,
            height: 104,
            fillsWidth: false
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

    private var rowMetadata: String {
        if item.imagePaths.count > 1 {
            return "\(item.databaseMetadataSummary) - \(item.imagePaths.count) media"
        }
        return item.databaseMetadataSummary
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
                        .overlay(Color.deltsHairline.opacity(0.34))

                    DetailTextSection(
                        title: "Form tip",
                        systemImage: "lightbulb",
                        text: item.formTip
                    )

                    DetailInstructionSection(instructions: item.instructions)

                    VStack(spacing: 0) {
                        DetailInfoRow(title: "Goal", value: item.goal.title, systemImage: "target")
                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.32))
                        DetailInfoRow(title: "Equipment", value: "\(item.equipment.title) - \(item.machineLabel)", systemImage: "dumbbell.fill")
                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.32))
                        DetailInfoRow(title: "Raw equipment", value: item.rawEquipment, systemImage: "wrench.and.screwdriver")
                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.32))
                        DetailInfoRow(title: "Category", value: item.category, systemImage: "tag")
                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.32))
                        DetailInfoRow(title: "Force", value: item.force, systemImage: "arrow.left.arrow.right")
                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.32))
                        DetailInfoRow(title: "Mechanic", value: item.mechanic, systemImage: "gearshape")
                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.32))
                        DetailInfoRow(title: "Primary muscles", value: item.primaryMusclesTitle, systemImage: "scope")
                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.32))
                        DetailInfoRow(title: "Secondary muscles", value: item.secondaryMusclesTitle, systemImage: "scope")
                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.32))
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
            height: 294
        )
        .frame(maxWidth: .infinity)
        .clipped()
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
                        .lineLimit(1)
                }

                Text(item.name)
                    .font(.system(.title, design: .rounded, weight: .bold))
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
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.deltsOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.deltsAccent, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.deltsHairline.opacity(0.28), lineWidth: 0.5)
                }
        }
        .deltsPressable()
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .deltsBottomActionBackground()
    }

    private var restText: String {
        item.restSeconds == 0 ? "--" : "\(item.restSeconds)s"
    }
}

private struct DetailTextSection: View {
    let title: String
    let systemImage: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
            Text(text)
                .font(.body)
                .foregroundStyle(Color.deltsMutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
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
    let restText: String

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                DetailMetric(title: "Sets", value: "\(item.sets)", systemImage: "number")
                Divider().frame(height: 48).overlay(Color.deltsHairline.opacity(0.34))
                DetailMetric(title: "Reps", value: item.reps, systemImage: "repeat")
                Divider().frame(height: 48).overlay(Color.deltsHairline.opacity(0.34))
                DetailMetric(title: "Rest", value: restText, systemImage: "timer")
            }

            Divider()
                .overlay(Color.deltsHairline.opacity(0.34))

            HStack(spacing: 0) {
                DetailMetric(title: "Level", value: item.level.title, systemImage: "chart.bar.fill")
                Divider().frame(height: 48).overlay(Color.deltsHairline.opacity(0.34))
                DetailMetric(title: "Body", value: item.muscleGroup.title, systemImage: item.muscleGroup.icon)
                Divider().frame(height: 48).overlay(Color.deltsHairline.opacity(0.34))
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
                .frame(width: 28, height: 28)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
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
                .foregroundStyle(Color.deltsSecondaryAccent)
                .frame(width: 30, height: 30)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)

            Spacer(minLength: 12)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .minimumScaleFactor(0.82)
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
