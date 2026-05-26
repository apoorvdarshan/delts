import SwiftUI

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
    @State private var searchText = ""
    @State private var selectedLevel: String?
    @State private var selectedRawEquipment: String?
    @State private var selectedPrimaryMuscle: String?
    @State private var selectedSecondaryMuscle: String?
    @State private var selectedForce: String?
    @State private var selectedMechanic: String?
    @State private var selectedCategory: String?
    @State private var selectedSort: ExerciseLibrarySort = .name

    private let service = ExerciseLibraryService.shared

    private var items: [ExerciseLibraryItem] {
        service.filtered(
            level: selectedLevel,
            rawEquipment: selectedRawEquipment,
            primaryMuscle: selectedPrimaryMuscle,
            secondaryMuscle: selectedSecondaryMuscle,
            force: selectedForce,
            mechanic: selectedMechanic,
            category: selectedCategory,
            sort: selectedSort,
            searchText: searchText
        )
    }

    private var hasActiveFilters: Bool {
        !searchText.isEmpty ||
            selectedLevel != nil ||
            selectedRawEquipment != nil ||
            selectedPrimaryMuscle != nil ||
            selectedSecondaryMuscle != nil ||
            selectedForce != nil ||
            selectedMechanic != nil ||
            selectedCategory != nil ||
            selectedSort != .name
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
                        onReset: hasActiveFilters ? {
                            withAnimation(.snappy) {
                                resetFilters()
                            }
                        } : nil
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
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 12) {
            WorkoutsSearchPill(searchText: $searchText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    filterMenuPill(
                        title: "Primary",
                        value: selectedPrimaryMuscle ?? "All",
                        systemImage: "scope"
                    ) {
                        menuChoice("All Primary", isSelected: selectedPrimaryMuscle == nil) {
                            selectedPrimaryMuscle = nil
                        }
                        ForEach(service.availablePrimaryMuscles, id: \.self) { muscle in
                            menuChoice(muscle, isSelected: selectedPrimaryMuscle == muscle) {
                                selectedPrimaryMuscle = muscle
                            }
                        }
                    }

                    filterMenuPill(
                        title: "Secondary",
                        value: selectedSecondaryMuscle ?? "All",
                        systemImage: "scope"
                    ) {
                        menuChoice("All Secondary", isSelected: selectedSecondaryMuscle == nil) {
                            selectedSecondaryMuscle = nil
                        }
                        ForEach(service.availableSecondaryMuscles, id: \.self) { muscle in
                            menuChoice(muscle, isSelected: selectedSecondaryMuscle == muscle) {
                                selectedSecondaryMuscle = muscle
                            }
                        }
                    }

                    filterMenuPill(
                        title: "Equipment",
                        value: equipmentFilterTitle,
                        systemImage: "dumbbell.fill"
                    ) {
                        menuChoice("All Equipment", isSelected: selectedRawEquipment == nil) {
                            selectedRawEquipment = nil
                        }
                        ForEach(service.availableRawEquipment, id: \.self) { equipment in
                            menuChoice(equipment, isSelected: selectedRawEquipment == equipment) {
                                selectedRawEquipment = equipment
                            }
                        }
                    }

                    filterMenuPill(
                        title: "Level",
                        value: selectedLevel ?? "All",
                        systemImage: "chart.bar.fill"
                    ) {
                        menuChoice("All Levels", isSelected: selectedLevel == nil) { selectedLevel = nil }
                        ForEach(service.availableLevels, id: \.self) { level in
                            menuChoice(level, isSelected: selectedLevel == level) { selectedLevel = level }
                        }
                    }

                    filterMenuPill(
                        title: "Force",
                        value: selectedForce ?? "All",
                        systemImage: "arrow.left.arrow.right"
                    ) {
                        menuChoice("All Forces", isSelected: selectedForce == nil) { selectedForce = nil }
                        ForEach(service.availableForces, id: \.self) { force in
                            menuChoice(force, isSelected: selectedForce == force) { selectedForce = force }
                        }
                    }

                    filterMenuPill(
                        title: "Mechanic",
                        value: selectedMechanic ?? "All",
                        systemImage: "gearshape"
                    ) {
                        menuChoice("All Mechanics", isSelected: selectedMechanic == nil) { selectedMechanic = nil }
                        ForEach(service.availableMechanics, id: \.self) { mechanic in
                            menuChoice(mechanic, isSelected: selectedMechanic == mechanic) { selectedMechanic = mechanic }
                        }
                    }

                    filterMenuPill(
                        title: "Category",
                        value: categoryFilterTitle,
                        systemImage: "tag"
                    ) {
                        menuChoice("All Categories", isSelected: selectedCategory == nil) { selectedCategory = nil }
                        ForEach(service.availableCategoryCounts) { categoryCount in
                            menuChoice(categoryMenuTitle(categoryCount), isSelected: selectedCategory == categoryCount.category) {
                                selectedCategory = categoryCount.category
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

                }
                .padding(.vertical, 1)
            }
        }
    }

    private var equipmentFilterTitle: String {
        if let selectedRawEquipment {
            return selectedRawEquipment
        }
        return "All"
    }

    private var categoryFilterTitle: String {
        selectedCategory ?? "All"
    }

    private func categoryMenuTitle(_ categoryCount: ExerciseCategoryCount) -> String {
        categoryCount.category
    }

    private func resetFilters() {
        searchText = ""
        selectedLevel = nil
        selectedRawEquipment = nil
        selectedPrimaryMuscle = nil
        selectedSecondaryMuscle = nil
        selectedForce = nil
        selectedMechanic = nil
        selectedCategory = nil
        selectedSort = .name
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
    var onReset: (() -> Void)?

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

            if let onReset {
                Button {
                    onReset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.deltsInferno)
                        .lineLimit(1)
                        .padding(.horizontal, 11)
                        .frame(height: 34)
                        .background(Color.deltsInferno.opacity(0.10), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(Color.deltsInferno.opacity(0.28), lineWidth: 0.5)
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

private struct ExerciseLibraryDetailView: View {
    let item: ExerciseLibraryItem

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    detailHero(width: screenWidth)

                    VStack(alignment: .leading, spacing: 24) {
                        DetailMetricGrid(item: item)

                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.34))

                        DetailInstructionSection(instructions: item.instructions)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 112)
                    .frame(width: screenWidth, alignment: .leading)
                }
                .frame(width: screenWidth, alignment: .leading)
            }
            .scrollIndicators(.hidden)
        }
        .deltsScreen()
        .contentMargins(.bottom, 104, for: .scrollContent)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailHero(width: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            AnimatedExerciseVisual(
                exerciseName: item.name,
                imagePaths: item.imagePaths,
                height: 294,
                allowsDerivedImageLookup: false
            )
            .frame(width: width, height: 294)

            LinearGradient(
                colors: [.clear, .black.opacity(0.18), .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)

                Text("\(item.primaryMusclesTitle) - \(item.rawEquipment) - \(item.rawLevel)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(width: width, alignment: .leading)
        }
        .frame(width: width, height: 294, alignment: .bottomLeading)
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(item.name) exercise visual"))
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
        VStack(spacing: 14) {
            DetailMetricRow(
                left: DetailMetricContent(title: "Level", value: item.rawLevel, systemImage: "chart.bar.fill"),
                right: DetailMetricContent(title: "Category", value: item.category, systemImage: "tag")
            )

            Divider()
                .overlay(Color.deltsHairline.opacity(0.34))

            DetailMetricRow(
                left: DetailMetricContent(title: "Force", value: item.force, systemImage: "arrow.left.arrow.right"),
                right: DetailMetricContent(title: "Mechanic", value: item.mechanic, systemImage: "gearshape")
            )

            Divider()
                .overlay(Color.deltsHairline.opacity(0.34))

            DetailMetricRow(
                left: DetailMetricContent(title: "Primary", value: item.primaryMusclesTitle, systemImage: "scope"),
                right: DetailMetricContent(title: "Secondary", value: item.secondaryMusclesTitle, systemImage: "scope")
            )

            Divider()
                .overlay(Color.deltsHairline.opacity(0.34))

            DetailMetric(title: "Equipment", value: item.rawEquipment, systemImage: "dumbbell.fill")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DetailMetricContent {
    let title: String
    let value: String
    let systemImage: String
}

private struct DetailMetricRow: View {
    let left: DetailMetricContent
    let right: DetailMetricContent

    var body: some View {
        HStack(spacing: 0) {
            DetailMetric(title: left.title, value: left.value, systemImage: left.systemImage)
            Divider().frame(height: 48).overlay(Color.deltsHairline.opacity(0.34))
            DetailMetric(title: right.title, value: right.value, systemImage: right.systemImage)
        }
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
