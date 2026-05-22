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
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Text("\(exercise.targetMuscle.title) - \(exercise.equipment.title)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.64))
                        }
                        Spacer()
                        Text(exercise.difficulty)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 10)
                            .background(Color.deltsInferno.opacity(0.24), in: Capsule())
                    }

                    HStack(spacing: 8) {
                        MetricPill(title: "Sets", value: "\(exercise.sets)", systemImage: "number", tint: .deltsElectricBlue)
                        MetricPill(title: "Reps", value: exercise.reps, systemImage: "repeat", tint: .deltsInferno)
                        MetricPill(title: "Rest", value: exercise.restDisplay, systemImage: "timer", tint: .white.opacity(0.78))
                    }

                    Text(exercise.formTip)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))
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
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
