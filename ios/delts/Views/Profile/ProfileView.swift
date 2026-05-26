import SwiftUI

struct ProfileView: View {
    @AppStorage("profile_dataset_level") private var datasetLevelRaw = ""
    @AppStorage("profile_dataset_primary_muscles") private var datasetPrimaryMusclesRaw = ""
    @AppStorage("profile_dataset_raw_equipment") private var datasetRawEquipmentRaw = ""

    private let service = ExerciseLibraryService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    profileHeader
                    datasetSummarySection
                    datasetLevelSection
                    datasetPrimarySection
                    datasetEquipmentSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 118)
            }
            .deltsScreen()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FreeExerciseDB")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.deltsAccent)
                .textCase(.uppercase)

            Text("Profile")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Color.deltsCharcoal)

            Text("Dataset fields only")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var datasetSummarySection: some View {
        DatasetProfileSection(title: "Dataset Summary", subtitle: "Available values loaded from exercises.json.", systemImage: "server.rack") {
            HStack(spacing: 0) {
                DatasetCountMetric(title: "Levels", value: service.availableLevels.count, systemImage: "chart.bar.fill")
                DatasetDivider()
                DatasetCountMetric(title: "Primary", value: service.availablePrimaryMuscles.count, systemImage: "scope")
                DatasetDivider()
                DatasetCountMetric(title: "Equipment", value: service.availableRawEquipment.count, systemImage: "dumbbell.fill")
            }
        }
    }

    private var datasetLevelSection: some View {
        DatasetProfileSection(title: "Dataset Level", subtitle: "Uses only the raw level values from the dataset.", systemImage: "chart.line.uptrend.xyaxis") {
            DatasetMenuRow(
                title: "Level",
                value: selectedLevelTitle,
                systemImage: "chart.bar.fill",
                options: service.availableLevels,
                clearTitle: "All levels"
            ) { selected in
                datasetLevelRaw = selected ?? ""
            }
        }
    }

    private var datasetPrimarySection: some View {
        DatasetProfileSection(title: "Dataset Primary", subtitle: "Uses only the primaryMuscles values from the dataset.", systemImage: "scope") {
            DatasetMultiSelectRow(
                title: "Primary muscles",
                value: selectedPrimaryTitle,
                systemImage: "scope",
                options: service.availablePrimaryMuscles,
                selection: selectedPrimaryMuscles
            ) { nextSelection in
                selectedPrimaryMuscles = nextSelection
            }
        }
    }

    private var datasetEquipmentSection: some View {
        DatasetProfileSection(title: "Dataset Equipment", subtitle: "Uses only the equipment values from the dataset.", systemImage: "dumbbell.fill") {
            DatasetMultiSelectRow(
                title: "Equipment",
                value: selectedEquipmentTitle,
                systemImage: "dumbbell.fill",
                options: service.availableRawEquipment,
                selection: selectedRawEquipment
            ) { nextSelection in
                selectedRawEquipment = nextSelection
            }
        }
    }

    private var selectedLevelTitle: String {
        service.availableLevels.contains(datasetLevelRaw) ? datasetLevelRaw : "All levels"
    }

    private var selectedPrimaryTitle: String {
        title(for: selectedPrimaryMuscles, emptyTitle: "All primary")
    }

    private var selectedEquipmentTitle: String {
        title(for: selectedRawEquipment, emptyTitle: "All equipment")
    }

    private var selectedPrimaryMuscles: Set<String> {
        get { decodeDatasetSet(datasetPrimaryMusclesRaw, validValues: service.availablePrimaryMuscles) }
        nonmutating set { datasetPrimaryMusclesRaw = encodeDatasetSet(newValue) }
    }

    private var selectedRawEquipment: Set<String> {
        get { decodeDatasetSet(datasetRawEquipmentRaw, validValues: service.availableRawEquipment) }
        nonmutating set { datasetRawEquipmentRaw = encodeDatasetSet(newValue) }
    }

    private func title(for values: Set<String>, emptyTitle: String) -> String {
        guard !values.isEmpty else { return emptyTitle }
        let sortedValues = values.sorted()
        if sortedValues.count <= 2 {
            return sortedValues.joined(separator: ", ")
        }
        return "\(sortedValues.count) selected"
    }

    private func decodeDatasetSet(_ rawValue: String, validValues: [String]) -> Set<String> {
        let validSet = Set(validValues)
        return Set(rawValue.split(separator: "|").map(String.init)).intersection(validSet)
    }

    private func encodeDatasetSet(_ values: Set<String>) -> String {
        values.sorted().joined(separator: "|")
    }
}

private struct DatasetProfileSection<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let content: Content

    init(title: String, subtitle: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.deltsAccent)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.deltsCharcoal)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.deltsMutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.deltsPanel.opacity(0.16))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.deltsHairline.opacity(0.38), lineWidth: 0.6)
                }
        }
    }
}

private struct DatasetMenuRow: View {
    let title: String
    let value: String
    let systemImage: String
    let options: [String]
    let clearTitle: String
    let onSelect: (String?) -> Void

    var body: some View {
        Menu {
            Button(clearTitle) {
                onSelect(nil)
            }

            ForEach(options, id: \.self) { option in
                Button(option) {
                    onSelect(option)
                }
            }
        } label: {
            DatasetRowLabel(title: title, value: value, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }
}

private struct DatasetMultiSelectRow: View {
    let title: String
    let value: String
    let systemImage: String
    let options: [String]
    let selection: Set<String>
    let onChange: (Set<String>) -> Void

    var body: some View {
        Menu {
            Button("Clear") {
                onChange([])
            }

            ForEach(options, id: \.self) { option in
                Button {
                    var nextSelection = selection
                    if nextSelection.contains(option) {
                        nextSelection.remove(option)
                    } else {
                        nextSelection.insert(option)
                    }
                    onChange(nextSelection)
                } label: {
                    HStack {
                        Text(option)
                        if selection.contains(option) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            DatasetRowLabel(title: title, value: value, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }
}

private struct DatasetRowLabel: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.deltsSecondaryAccent)
                .frame(width: 28)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)

            Spacer(minLength: 12)

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct DatasetCountMetric: View {
    let title: String
    let value: Int
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsAccent)
                .frame(width: 22, height: 22)

            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)
                .monospacedDigit()

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }
}

private struct DatasetDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.38))
            .frame(width: 0.6, height: 58)
    }
}
