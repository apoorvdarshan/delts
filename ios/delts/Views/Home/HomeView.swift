import SwiftUI

struct HomeView: View {
    @State private var selectedPrimaryMuscle: String?
    @State private var selectedRawEquipment: String?
    @State private var selectedLevel: String?
    @State private var selectedCategory: String?
    @State private var shownItems: [ExerciseLibraryItem] = []

    private let service = ExerciseLibraryService.shared

    private var matchingItems: [ExerciseLibraryItem] {
        service.filtered(
            level: selectedLevel,
            rawEquipment: selectedRawEquipment,
            primaryMuscle: selectedPrimaryMuscle,
            secondaryMuscle: nil,
            force: nil,
            mechanic: nil,
            category: selectedCategory,
            sort: .name,
            searchText: ""
        )
    }

    private var heroItem: ExerciseLibraryItem? {
        matchingItems.first ?? service.exercises.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    startHeader
                    startHero
                    primaryMuscleStep
                    equipmentStep
                    datasetFilterStep
                    exercisePreview
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 122)
            }
            .deltsScreen()
            .navigationTitle("Start")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                startBar
            }
        }
    }

    private var startHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("delts")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.deltsAccent)
                .textCase(.uppercase)

            Text("Start")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Color.deltsCharcoal)

            Text(datasetHeaderSummary)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var startHero: some View {
        let item = heroItem

        return ZStack(alignment: .bottomLeading) {
            AnimatedExerciseVisual(
                exerciseName: item?.name,
                imagePaths: item?.imagePaths ?? [],
                height: 248,
                allowsDerivedImageLookup: false
            )
            .saturation(0.74)
            .contrast(1.06)
            .brightness(-0.07)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            LinearGradient(
                colors: [
                    Color.deltsBackground.opacity(0.10),
                    .black.opacity(0.26),
                    .black.opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            VStack(alignment: .leading, spacing: 16) {
                Label("FreeExerciseDB", systemImage: "server.rack")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.86))

                Spacer(minLength: 44)

                VStack(alignment: .leading, spacing: 9) {
                    Text(item?.name ?? "Exercise Library")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    Text(item.map { heroSubtitle(for: $0) } ?? "Dataset fields only")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.76))
                        .lineLimit(2)
                }

                if let item {
                    StartDatasetStrip(item: item)
                }
            }
            .padding(20)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
        }
    }

    private var datasetHeaderSummary: String {
        [
            selectedPrimaryMuscle ?? "All primary",
            selectedRawEquipment ?? "All equipment",
            selectedLevel ?? "All levels"
        ].joined(separator: " - ")
    }

    private func heroSubtitle(for item: ExerciseLibraryItem) -> String {
        "\(item.primaryMusclesTitle) - \(item.rawEquipment) - \(item.rawLevel)"
    }

    private var primaryMuscleStep: some View {
        StartSection(
            index: "01",
            title: "Primary",
            subtitle: "Choose from the dataset primaryMuscles field."
        ) {
            StartHorizontalRail {
                StartOptionButton(title: "All", systemImage: "scope", isSelected: selectedPrimaryMuscle == nil) {
                    selectedPrimaryMuscle = nil
                    shownItems = []
                }
                ForEach(service.availablePrimaryMuscles, id: \.self) { muscle in
                    StartOptionButton(title: muscle, systemImage: "scope", isSelected: selectedPrimaryMuscle == muscle) {
                        selectedPrimaryMuscle = muscle
                        shownItems = []
                    }
                }
            }
        }
    }

    private var equipmentStep: some View {
        StartSection(
            index: "02",
            title: "Equipment",
            subtitle: "Choose from the dataset equipment field."
        ) {
            StartHorizontalRail {
                StartOptionButton(title: "All", systemImage: "dumbbell.fill", isSelected: selectedRawEquipment == nil) {
                    selectedRawEquipment = nil
                    shownItems = []
                }
                ForEach(service.availableRawEquipment, id: \.self) { equipment in
                    StartOptionButton(title: equipment, systemImage: "dumbbell.fill", isSelected: selectedRawEquipment == equipment) {
                        selectedRawEquipment = equipment
                        shownItems = []
                    }
                }
            }
        }
    }

    private var datasetFilterStep: some View {
        StartSection(
            index: "03",
            title: "Dataset",
            subtitle: "Filter by raw level and category."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                StartHorizontalRail {
                    StartOptionButton(title: "All levels", systemImage: "chart.bar.fill", isSelected: selectedLevel == nil) {
                        selectedLevel = nil
                        shownItems = []
                    }
                    ForEach(service.availableLevels, id: \.self) { level in
                        StartOptionButton(title: level, systemImage: "chart.bar.fill", isSelected: selectedLevel == level) {
                            selectedLevel = level
                            shownItems = []
                        }
                    }
                }

                StartHorizontalRail {
                    StartOptionButton(title: "All categories", systemImage: "tag", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                        shownItems = []
                    }
                    ForEach(service.availableCategoryCounts) { categoryCount in
                        StartOptionButton(title: categoryCount.category, systemImage: "tag", isSelected: selectedCategory == categoryCount.category) {
                            selectedCategory = categoryCount.category
                            shownItems = []
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var exercisePreview: some View {
        if !shownItems.isEmpty {
            StartSection(
                index: "04",
                title: "Exercises",
                subtitle: "\(shownItems.count) matching dataset record\(shownItems.count == 1 ? "" : "s")."
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(shownItems.prefix(5)) { item in
                        StartExercisePreviewRow(item: item)
                    }
                }
            }
        }
    }

    private var startBar: some View {
        VStack(spacing: 8) {
            PrimaryButton(
                title: "Show Dataset Exercises",
                systemImage: "list.clipboard.fill"
            ) {
                shownItems = matchingItems
            }

            Text("\(matchingItems.count) currently match the selected dataset fields.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .deltsBottomActionBackground()
    }

}

private struct StartSection<Content: View>: View {
    let index: String
    let title: String
    let subtitle: String
    let content: Content

    init(index: String, title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.index = index
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(index)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.deltsAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.deltsMutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
    }
}

private struct StartDatasetStrip: View {
    let item: ExerciseLibraryItem

    var body: some View {
        HStack(spacing: 0) {
            StartHeroMetric(title: "Primary", value: item.primaryMusclesTitle, systemImage: "scope")
            StartHeroDivider()
            StartHeroMetric(title: "Level", value: item.rawLevel, systemImage: "chart.bar.fill")
            StartHeroDivider()
            StartHeroMetric(title: "Gear", value: item.rawEquipment, systemImage: "dumbbell.fill")
            StartHeroDivider()
            StartHeroMetric(title: "Category", value: item.category, systemImage: "tag")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(.black.opacity(0.36), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct StartHeroMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsAccent)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct StartHeroDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.16))
            .frame(width: 0.5, height: 42)
            .padding(.horizontal, 8)
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

private struct StartExercisePreviewRow: View {
    let item: ExerciseLibraryItem

    var body: some View {
        HStack(spacing: 14) {
            AnimatedExerciseVisual(
                exerciseName: item.name,
                imagePaths: item.imagePaths,
                height: 82,
                fillsWidth: false,
                allowsDerivedImageLookup: false
            )
            .frame(width: 82, height: 82)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(2)

                Text("\(item.primaryMusclesTitle) - \(item.rawEquipment) - \(item.rawLevel)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(item.databaseMetadataSummary)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsSecondaryAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}
