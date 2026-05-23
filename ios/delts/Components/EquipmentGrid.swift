import SwiftUI

struct EquipmentGrid: View {
    var equipment: [Equipment] = Equipment.allCases
    @Binding var selection: Set<Equipment>

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(equipment) { item in
                let isSelected = selection.contains(item)
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        if isSelected {
                            selection.remove(item)
                        } else {
                            selection.insert(item)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: item.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.white : Color.deltsAccent)
                            .frame(width: 30, height: 30)
                            .background(isSelected ? Color.deltsAccent : Color.deltsAccent.opacity(0.12), in: Circle())

                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)
                    .frame(minHeight: 54)
                    .background(
                        isSelected ? Color.deltsAccent.opacity(0.14) : Color.clear,
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.deltsAccent.opacity(0.6) : Color(uiColor: .separator).opacity(0.22), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
