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
                        .foregroundStyle(selection == group ? .white : .primary)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 14)
                        .background(
                            selection == group ? Color.deltsAccent : Color.clear,
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(selection == group ? Color.deltsAccent : Color(uiColor: .separator).opacity(0.28), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }
}
