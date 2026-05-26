import SwiftUI

struct MuscleGroupPicker: View {
    @Binding var selection: MuscleGroup
    @Namespace private var selectionRail
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(MuscleGroup.allCases) { group in
                    let isSelected = selection == group

                    Button {
                        let animation: Animation? = reduceMotion ? nil : .spring(response: 0.30, dampingFraction: 0.88)
                        withAnimation(animation) {
                            selection = group
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: group.icon)
                                .font(.system(size: 13, weight: .semibold))
                            Text(group.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.86)
                        }
                        .font(.subheadline.weight(isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsCharcoal.opacity(0.78))
                        .padding(.horizontal, 11)
                        .frame(height: 42)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.deltsAccent.opacity(0.12))
                                    .matchedGeometryEffect(id: "selectedMuscleGroup", in: selectionRail)
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if isSelected {
                                Capsule()
                                    .fill(Color.deltsAccent)
                                    .frame(width: 18, height: 2)
                                    .offset(y: -4)
                            }
                        }
                        .contentShape(Capsule())
                    }
                    .deltsPressable()
                    .accessibilityLabel(Text(group.title))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(4)
        }
        .background(Color.deltsPanel.opacity(0.36), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.deltsHairline.opacity(0.46), lineWidth: 0.5)
        )
        .accessibilityElement(children: .contain)
    }
}
