import SwiftUI

struct ExerciseCard: View {
    let exercise: WorkoutExercise
    var showsStartButton: Bool = true
    var startAction: (() -> Void)?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                AnimatedExerciseVisual(
                    muscleGroup: exercise.targetMuscle,
                    exerciseName: exercise.name,
                    equipment: exercise.equipment,
                    height: 150
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                            Text("\(exercise.targetMuscle.title) - \(exercise.equipment.title)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(exercise.difficulty)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.deltsInk)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 10)
                            .background(Color.deltsGold, in: Capsule())
                            .overlay(Capsule().stroke(Color.deltsInk.opacity(0.7), lineWidth: 1))
                    }

                    HStack(spacing: 8) {
                        MetricPill(title: "Sets", value: "\(exercise.sets)", systemImage: "number", tint: .deltsElectricBlue)
                        MetricPill(title: "Reps", value: exercise.reps, systemImage: "repeat", tint: .deltsInferno)
                        MetricPill(title: "Rest", value: exercise.restDisplay, systemImage: "timer", tint: .white.opacity(0.78))
                    }

                    Text(exercise.formTip)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }

                if showsStartButton, let startAction {
                    Button(action: startAction) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start")
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.deltsInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.deltsElectricBlue.opacity(0.14), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(Color.deltsInk.opacity(0.62), lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
