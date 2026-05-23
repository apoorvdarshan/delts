import SwiftData
import SwiftUI

private enum ActiveWorkoutLogField: Hashable {
    case weight(exerciseIndex: Int, setIndex: Int)
    case reps(exerciseIndex: Int, setIndex: Int)
}

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ActiveWorkoutViewModel
    @FocusState private var focusedField: ActiveWorkoutLogField?

    init(plan: WorkoutPlan, startIndex: Int = 0) {
        _viewModel = StateObject(wrappedValue: ActiveWorkoutViewModel(plan: plan, startIndex: startIndex))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let exercise = viewModel.currentExercise {
                    exerciseSection(exercise)
                    setLogger(for: exercise)
                    restStrip(exercise)
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .deltsScreen()
        .contentMargins(.bottom, 106, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Active Workout")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if viewModel.currentExercise != nil {
                bottomPrimaryAction
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                    .background(.bar)
            }
        }
        .toolbar {
            if viewModel.currentExercise != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save & Exit") {
                        finishWorkout()
                    }
                    .tint(Color.deltsAccent)
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.currentExerciseIndex)
    }

    private func exerciseSection(_ exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottomLeading) {
                AnimatedExerciseVisual(
                    muscleGroup: exercise.targetMuscle,
                    exerciseName: exercise.name,
                    equipment: exercise.equipment,
                    height: 252
                )

                LinearGradient(
                    colors: [
                        .black.opacity(0.00),
                        .black.opacity(0.16),
                        .black.opacity(0.74)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(currentPositionText)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(.black.opacity(0.52), in: Capsule())

                        Spacer(minLength: 8)

                        Text(viewModel.plan.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.86))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(.black.opacity(0.38), in: Capsule())
                    }

                    Text(exercise.name)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.66)

                    Text("\(exercise.targetMuscle.title) - \(exercise.equipment.title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))
                }
                .padding(16)
            }

            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 0) {
                    exerciseMetric(title: "Sets", value: "\(exercise.sets)", systemImage: "number")
                    metricDivider
                    exerciseMetric(title: "Reps", value: exercise.reps, systemImage: "repeat", tint: .deltsInferno)
                    metricDivider
                    exerciseMetric(title: "Rest", value: exercise.restDisplay, systemImage: "timer", tint: .deltsSecondaryAccent)
                }

                ProgressView(value: positionProgress)
                    .tint(Color.deltsAccent)
                    .accessibilityLabel(currentPositionText)

                Text(exercise.formTip)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func setLogger(for exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Set Logger")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(completedSetCount(for: exercise)) / \(max(exercise.sets, 1)) done")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
            }

            VStack(spacing: 0) {
                setLoggerHeader

                ForEach(0..<max(exercise.sets, 1), id: \.self) { setIndex in
                    Divider()
                        .padding(.leading, 12)

                    setLoggerRow(setIndex)
                }
            }
            .background(Color.deltsCard.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(uiColor: .separator).opacity(0.22), lineWidth: 0.5)
            }
        }
    }

    private var setLoggerHeader: some View {
        HStack(spacing: 10) {
            Text("Set")
                .frame(width: 44, alignment: .leading)
            Text("Weight")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Reps")
                .frame(width: 74, alignment: .leading)
            Image(systemName: "checkmark.circle")
                .opacity(0)
                .frame(width: 42)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(Color.deltsMutedText)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private func setLoggerRow(_ setIndex: Int) -> some View {
        HStack(spacing: 10) {
            Text("\(setIndex + 1)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, alignment: .leading)

            TextField("0", text: weightBinding(setIndex))
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .frame(height: 38)
                .background(Color.deltsPanel.opacity(0.72), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .focused(
                    $focusedField,
                    equals: .weight(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex)
                )

            TextField("0", text: repsBinding(setIndex))
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .frame(width: 74, height: 38)
                .background(Color.deltsPanel.opacity(0.72), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .focused(
                    $focusedField,
                    equals: .reps(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex)
                )

            Button {
                viewModel.toggleSet(setIndex)
            } label: {
                Image(systemName: isSetComplete(setIndex) ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSetComplete(setIndex) ? Color.deltsAccent : Color.secondary)
                    .frame(width: 42, height: 38)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSetComplete(setIndex) ? "Mark set \(setIndex + 1) incomplete" : "Mark set \(setIndex + 1) complete")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func restStrip(_ exercise: WorkoutExercise) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.deltsInferno)
                .frame(width: 32, height: 32)
                .background(Color.deltsInferno.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Rest")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Between sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(exercise.restDisplay)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 2)
        .overlay(alignment: .top) {
            stripSeparator
        }
        .overlay(alignment: .bottom) {
            stripSeparator
        }
    }

    @ViewBuilder
    private var bottomPrimaryAction: some View {
        if viewModel.isLastExercise {
            PrimaryButton(title: "Finish Workout", systemImage: "checkmark.seal.fill") {
                finishWorkout()
            }
        } else {
            PrimaryButton(title: "Next Exercise", systemImage: "arrow.right") {
                focusedField = nil
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    viewModel.nextExercise()
                }
            }
        }
    }

    private func exerciseMetric(
        title: String,
        value: String,
        systemImage: String,
        tint: Color = .deltsAccent
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(Color(uiColor: .separator).opacity(0.25))
            .frame(width: 0.5, height: 36)
            .padding(.horizontal, 10)
    }

    private var stripSeparator: some View {
        Rectangle()
            .fill(Color(uiColor: .separator).opacity(0.24))
            .frame(height: 0.5)
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(Color.deltsInferno)
                Text("No exercises found")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var positionProgress: Double {
        guard !viewModel.exercises.isEmpty else { return 0 }
        return Double(viewModel.currentExerciseIndex + 1) / Double(viewModel.exercises.count)
    }

    private var currentPositionText: String {
        guard !viewModel.exercises.isEmpty else { return "Exercise 0 of 0" }
        return "Exercise \(viewModel.currentExerciseIndex + 1) of \(viewModel.exercises.count)"
    }

    private func completedSetCount(for exercise: WorkoutExercise) -> Int {
        let totalSets = max(exercise.sets, 1)
        return (0..<totalSets).filter { isSetComplete($0) }.count
    }

    private func isSetComplete(_ setIndex: Int) -> Bool {
        viewModel.completedSets[safe: viewModel.currentExerciseIndex]?[safe: setIndex] ?? false
    }

    private func weightBinding(_ setIndex: Int) -> Binding<String> {
        Binding {
            viewModel.weightInputs[safe: viewModel.currentExerciseIndex]?[safe: setIndex] ?? ""
        } set: { newValue in
            guard viewModel.weightInputs.indices.contains(viewModel.currentExerciseIndex),
                  viewModel.weightInputs[viewModel.currentExerciseIndex].indices.contains(setIndex)
            else { return }
            viewModel.weightInputs[viewModel.currentExerciseIndex][setIndex] = newValue
        }
    }

    private func repsBinding(_ setIndex: Int) -> Binding<String> {
        Binding {
            viewModel.repInputs[safe: viewModel.currentExerciseIndex]?[safe: setIndex] ?? ""
        } set: { newValue in
            guard viewModel.repInputs.indices.contains(viewModel.currentExerciseIndex),
                  viewModel.repInputs[viewModel.currentExerciseIndex].indices.contains(setIndex)
            else { return }
            viewModel.repInputs[viewModel.currentExerciseIndex][setIndex] = newValue
        }
    }

    private func finishWorkout() {
        focusedField = nil
        let completed = viewModel.makeCompletedWorkout()
        modelContext.insert(completed)
        try? modelContext.save()
        dismiss()
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
