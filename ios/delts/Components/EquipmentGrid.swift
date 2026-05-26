import SwiftUI

struct EquipmentGrid: View {
    var equipment: [Equipment] = Equipment.allCases
    @Binding var selection: Set<Equipment>
    @State private var feedbackTrigger = false

    private var sections: [EquipmentSection] {
        EquipmentSection.all.compactMap { section in
            let availableItems = section.items.filter { equipment.contains($0) }
            guard !availableItems.isEmpty else { return nil }
            return EquipmentSection(title: section.title, items: availableItems)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                        .textCase(.uppercase)
                        .padding(.horizontal, 2)

                    VStack(spacing: 0) {
                        ForEach(section.items.indices, id: \.self) { index in
                            let item = section.items[index]
                            EquipmentChecklistRow(
                                item: item,
                                isSelected: selection.contains(item)
                            ) {
                                toggle(item)
                            }

                            if index < section.items.count - 1 {
                                Divider()
                                    .padding(.leading, 58)
                            }
                        }
                    }
                    .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: feedbackTrigger)
    }

    private func toggle(_ item: Equipment) {
        withAnimation(.snappy(duration: 0.18)) {
            if selection.contains(item) {
                selection.remove(item)
            } else {
                selection.insert(item)
            }
        }
        feedbackTrigger.toggle()
    }
}

private struct EquipmentSection: Identifiable {
    let title: String
    let items: [Equipment]

    var id: String { title }

    static let all: [EquipmentSection] = [
        EquipmentSection(
            title: "Free Weights",
            items: [.dumbbells, .barbell, .bench]
        ),
        EquipmentSection(
            title: "Machines",
            items: [
                .cableMachine,
                .smithMachine,
                .chestPress,
                .shoulderPress,
                .latPulldown,
                .rowMachine,
                .legPress,
                .legExtension,
                .legCurl
            ]
        ),
        EquipmentSection(
            title: "Bodyweight & Cardio",
            items: [.pullUpBar, .treadmill, .bodyweight]
        )
    ]
}

private struct EquipmentChecklistRow: View {
    let item: Equipment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsSecondaryAccent)
                    .frame(width: 34, height: 34)
                    .accessibilityHidden(true)

                Text(item.title)
                    .font(.body)
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isSelected ? "checkmark" : "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsHairline)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 54)
            .background(isSelected ? Color.deltsAccent.opacity(0.08) : Color.clear)
            .contentShape(Rectangle())
        }
        .deltsPressable()
        .accessibilityLabel(item.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isSelected ? "Double tap to remove from available equipment." : "Double tap to add to available equipment.")
        .equipmentSelectedTrait(isSelected)
    }
}

private extension View {
    @ViewBuilder
    func equipmentSelectedTrait(_ isSelected: Bool) -> some View {
        if isSelected {
            accessibilityAddTraits(.isSelected)
        } else {
            self
        }
    }
}
