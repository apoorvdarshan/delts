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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Library")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
                    .textCase(.uppercase)

                Text("Workouts")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.deltsCharcoal)

                Text(selectedMode.subtitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            HStack(spacing: 10) {
                ForEach(WorkoutsMode.allCases) { mode in
                    Button {
                        withAnimation(.snappy(duration: 0.18)) {
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
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.deltsHairline.opacity(0.34))
                .frame(height: 0.5)
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
        case .history: return "clock.arrow.circlepath"
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

    private var hasLibrarySelection: Bool {
        !searchText.isEmpty ||
            selectedMuscleGroup != nil ||
            selectedLevel != nil ||
            selectedGoal != nil ||
            selectedEquipment != nil ||
            selectedEquipmentFamily != .all
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                librarySummary
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 14)

                filters
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
                        systemImage: "line.3.horizontal.decrease.circle",
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
                .buttonStyle(.plain)
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
                HStack(spacing: 8) {
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
                .padding(.horizontal, 20)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterMenu(
                        title: "Level",
                        value: selectedLevel?.title ?? "All",
                        systemImage: "chart.bar.fill"
                    ) {
                        menuChoice("All Levels", isSelected: selectedLevel == nil) { selectedLevel = nil }
                        ForEach(ExperienceLevel.allCases) { level in
                            menuChoice(level.title, isSelected: selectedLevel == level) { selectedLevel = level }
                        }
                    }

                    filterMenu(
                        title: "Goal",
                        value: selectedGoal?.title ?? "All",
                        systemImage: "target"
                    ) {
                        menuChoice("All Goals", isSelected: selectedGoal == nil) { selectedGoal = nil }
                        ForEach(FitnessGoal.profileCases + [.beginnerForm]) { goal in
                            menuChoice(goal.title, isSelected: selectedGoal == goal) { selectedGoal = goal }
                        }
                    }

                    filterMenu(
                        title: "Equipment",
                        value: equipmentFilterTitle,
                        systemImage: "dumbbell.fill"
                    ) {
                        menuChoice("All Equipment", isSelected: selectedEquipment == nil && selectedEquipmentFamily == .all) {
                            selectedEquipment = nil
                            selectedEquipmentFamily = .all
                        }
                        Section("Family") {
                            ForEach(ExerciseEquipmentFamily.allCases.filter { $0 != .all }) { family in
                                menuChoice(family.title, isSelected: selectedEquipment == nil && selectedEquipmentFamily == family) {
                                    selectedEquipment = nil
                                    selectedEquipmentFamily = family
                                }
                            }
                        }
                        Section("Specific") {
                            ForEach(Equipment.allCases) { equipment in
                                menuChoice(equipment.title, isSelected: selectedEquipment == equipment) {
                                    selectedEquipment = equipment
                                    selectedEquipmentFamily = .all
                                }
                            }
                        }
                    }

                    filterMenu(
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
                            Label("Reset", systemImage: "arrow.counterclockwise")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.deltsInferno)
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .frame(height: 36)
                                .background(Color.deltsInferno.opacity(0.10), in: Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(Color.deltsInferno.opacity(0.34), lineWidth: 0.5)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
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
        return "All"
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
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(value == "All" ? Color.deltsSecondaryAccent : Color.deltsAccent)

                Text(value == "All" ? title : "\(title): \(value)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Color.deltsPanel.opacity(value == "All" ? 0.42 : 0.56), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        (value == "All" ? Color.deltsHairline : Color.deltsAccent).opacity(value == "All" ? 0.44 : 0.36),
                        lineWidth: 0.5
                    )
            }
        }
        .buttonStyle(.plain)
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
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 18)
    }
}

private struct WorkoutHistoryListView: View {
    let workouts: [CompletedWorkout]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
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
                        trailingSystemImage: "clock.arrow.circlepath"
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
        .buttonStyle(.plain)
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
            return "\(item.machineLabel) - \(item.imagePaths.count) media"
        }
        return item.machineLabel
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
                HistorySummaryItem(value: "\(completedSets)/\(totalSets)", label: "sets", systemImage: "checkmark.circle")
                HistorySummaryItem(value: "\(workout.durationMinutes)m", label: "duration", systemImage: "clock")
            }

            VStack(alignment: .leading, spacing: 4) {
                HistorySummaryItem(value: "\(logs.count)", label: logs.count == 1 ? "exercise" : "exercises", systemImage: "figure.strengthtraining.traditional")
                HistorySummaryItem(value: "\(completedSets)/\(totalSets)", label: "sets", systemImage: "checkmark.circle")
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
            Circle()
                .fill(Color.deltsSecondaryAccent.opacity(0.14))
                .overlay {
                    Circle()
                        .stroke(Color.deltsHairline.opacity(0.38), lineWidth: 0.5)
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

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Form tip", systemImage: "lightbulb")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.deltsCharcoal)
                        Text(item.formTip)
                            .font(.body)
                            .foregroundStyle(Color.deltsMutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 0) {
                        DetailInfoRow(title: "Goal", value: item.goal.title, systemImage: "target")
                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.32))
                        DetailInfoRow(title: "Equipment", value: "\(item.equipment.title) - \(item.machineLabel)", systemImage: "dumbbell.fill")
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
            height: 326
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
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
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
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.bar)
    }

    private var restText: String {
        item.restSeconds == 0 ? "--" : "\(item.restSeconds)s"
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
                WorkoutSummaryMetric(value: "\(completedSets)/\(totalSets)", title: "Sets", systemImage: "checkmark.circle")
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

                Label("\(completedSets)/\(exercise.sets.count)", systemImage: "checkmark.circle.fill")
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
            Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
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
