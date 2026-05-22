import SwiftUI

struct EquipmentGrid: View {
    var equipment: [Equipment] = Equipment.allCases
    @Binding var selection: Set<Equipment>

    private let columns = [
        GridItem(.adaptive(minimum: 148), spacing: 12)
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
                            .foregroundStyle(isSelected ? Color.white : Color.deltsElectricBlue)
                            .frame(width: 30, height: 30)
                            .background(isSelected ? Color.deltsElectricBlue : Color.deltsElectricBlue.opacity(0.12), in: Circle())

                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .frame(minHeight: 58)
                    .background(
                        isSelected ? Color.deltsElectricBlue.opacity(0.18) : Color.white.opacity(0.035),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .deltsGlassSurface(
                        cornerRadius: 18,
                        tint: isSelected ? Color.deltsElectricBlue.opacity(0.2) : Color.white.opacity(0.1),
                        interactive: true
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? Color.deltsElectricBlue.opacity(0.9) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .deltsGlassButton()
            }
        }
    }
}
