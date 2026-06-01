import SwiftUI

struct ExerciseFilterOption: Identifiable, Hashable {
    let id: String
    let title: String

    init(_ title: String, id: String? = nil) {
        self.id = id ?? title
        self.title = title
    }
}

struct ExerciseFilterSelectionSheet: View {
    let title: String
    let allTitle: String
    let systemImage: String
    let options: [ExerciseFilterOption]
    @Binding var selection: Set<String>

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredOptions: [ExerciseFilterOption] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return options }
        return options.filter { $0.title.lowercased().contains(query) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    filterRow(
                        title: allTitle,
                        subtitle: "Show every option",
                        isSelected: selection.isEmpty
                    ) {
                        selection.removeAll()
                    }

                    ForEach(filteredOptions) { option in
                        filterRow(
                            title: option.title,
                            subtitle: nil,
                            isSelected: selection.contains(option.id)
                        ) {
                            toggle(option.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.deltsBackground.ignoresSafeArea())
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search \(title.lowercased())")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.deltsAccent)
                }
            }
        }
    }

    private func filterRow(
        title: String,
        subtitle: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsSecondaryAccent)
                    .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.deltsMutedText)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 10)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsMutedText)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 58)
            .background(
                Color.deltsPanel.opacity(isSelected ? 0.42 : 0.22),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.deltsAccent.opacity(0.52) : Color.deltsHairline.opacity(0.24), lineWidth: 0.8)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .deltsPressable()
    }

    private func toggle(_ value: String) {
        if selection.contains(value) {
            selection.remove(value)
        } else {
            selection.insert(value)
        }
    }
}
