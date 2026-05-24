import SwiftUI

struct ExerciseCard: View {
    let exercise: WorkoutExercise
    var showsStartButton: Bool = true
    var startAction: (() -> Void)?

    var body: some View {
        Button {
            startAction?()
        } label: {
            HStack(alignment: .center, spacing: 14) {
                AnimatedExerciseVisual(
                    muscleGroup: exercise.targetMuscle,
                    exerciseName: exercise.name,
                    equipment: exercise.equipment,
                    height: 94,
                    fillsWidth: false
                )
                .frame(width: 104, height: 94)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 7) {
                    Text(exercise.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.deltsCharcoal)
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)

                    Text("\(exercise.targetMuscle.title) - \(exercise.equipment.title)")
                        .font(.subheadline)
                        .foregroundStyle(Color.deltsMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text("\(exercise.sets) sets - \(exercise.reps) reps - \(exercise.restDisplay) rest")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 4)

                if showsStartButton {
                    Image(systemName: "play.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.deltsAccent)
                        .frame(width: 30, height: 30)
                        .accessibilityLabel("Start exercise")
                }
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .disabled(startAction == nil)
    }
}
