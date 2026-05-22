import SwiftUI

struct MuscleGroupPicker: View {
    @Binding var selection: MuscleGroup

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MuscleGroup.allCases) { group in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            selection = group
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: group.icon)
                            Text(group.title)
                                .lineLimit(1)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selection == group ? .white : .white.opacity(0.72))
                        .padding(.vertical, 11)
                        .padding(.horizontal, 14)
                        .background(
                            selection == group ? Color.deltsElectricBlue.opacity(0.26) : Color.white.opacity(0.06),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(selection == group ? Color.deltsElectricBlue : Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

