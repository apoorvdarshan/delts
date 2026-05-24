import SwiftData
import SwiftUI
import UIKit

private enum ActiveWorkoutLogField: Hashable {
    case weight(exerciseIndex: Int, setIndex: Int)
    case reps(exerciseIndex: Int, setIndex: Int)
}

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject private var viewModel: ActiveWorkoutViewModel
    @FocusState private var focusedField: ActiveWorkoutLogField?
    @State private var restSecondsRemaining = 0
    @State private var restTimerRunning = false

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
        .contentMargins(.bottom, dynamicTypeSize.isAccessibilitySize ? 148 : 106, for: .scrollContent)
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
                    Button {
                        finishWorkout()
                    } label: {
                        Label("Save & Exit", systemImage: "tray.and.arrow.down.fill")
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
        .onChange(of: viewModel.currentExerciseIndex) {
            resetRestTimer()
        }
        .task(id: restTimerRunning) {
            guard restTimerRunning else { return }

            while restSecondsRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                restSecondsRemaining -= 1
            }

            if restSecondsRemaining <= 0 {
                restTimerRunning = false
            }
        }
    }

    private func exerciseSection(_ exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            exerciseHero(exercise)
            exerciseDetails(exercise)
        }
    }

    private func setLogger(for exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Working Sets")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)

                Spacer()

                Text("\(completedSetCount(for: exercise)) / \(max(exercise.sets, 1)) done")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
            }

            VStack(spacing: 0) {
                ForEach(0..<max(exercise.sets, 1), id: \.self) { setIndex in
                    if setIndex > 0 {
                        Divider()
                            .overlay(Color.deltsHairline.opacity(0.38))
                            .padding(.leading, dynamicTypeSize.isAccessibilitySize ? 0 : 58)
                    }

                    setLoggerRow(setIndex)
                }
            }
            .overlay(alignment: .top) {
                stripSeparator.opacity(0.72)
            }
            .overlay(alignment: .bottom) {
                stripSeparator.opacity(0.72)
            }
        }
    }

    private func setLoggerRow(_ setIndex: Int) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stackedSetLoggerRow(setIndex)
            } else {
                ViewThatFits(in: .horizontal) {
                    standardSetLoggerRow(setIndex)
                        .frame(minWidth: 310)
                    stackedSetLoggerRow(setIndex)
                }
            }
        }
        .background(isSetComplete(setIndex) ? Color.deltsSecondaryAccent.opacity(0.08) : Color.clear)
    }

    private func restStrip(_ exercise: WorkoutExercise) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.deltsSecondaryAccent)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rest")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                Text("Between sets")
                    .font(.caption)
                    .foregroundStyle(Color.deltsMutedText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(restTimerText(defaultSeconds: exercise.restSeconds))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .monospacedDigit()

                HStack(spacing: 8) {
                    Button {
                        toggleRestTimer(defaultSeconds: exercise.restSeconds)
                    } label: {
                        Label(restTimerRunning ? "Pause" : restSecondsRemaining > 0 ? "Resume" : "Start", systemImage: restTimerRunning ? "pause.fill" : "play.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.deltsOnAccent)
                            .lineLimit(1)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 10)
                            .background(Color.deltsAccent, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    if restSecondsRemaining > 0 {
                        Button {
                            resetRestTimer()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.deltsSecondaryAccent)
                                .frame(width: 30, height: 30)
                                .background(Color.deltsPanel.opacity(0.34), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Reset rest timer")
                    }
                }
            }
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
        VStack(spacing: 10) {
            if viewModel.isLastExercise {
                PrimaryButton(title: "Finish Workout", systemImage: "checkmark.seal.fill") {
                    finishWorkout()
                }
            } else {
                HStack(spacing: 10) {
                    Button {
                        goToNextExercise()
                    } label: {
                        Label("Skip", systemImage: "forward.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.deltsCharcoal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.deltsPanel.opacity(0.28), in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.5)
                            }
                    }
                    .buttonStyle(.plain)

                    PrimaryButton(title: "Next", systemImage: "arrow.right") {
                        goToNextExercise()
                    }
                }
            }
        }
    }

    private func exerciseHero(_ exercise: WorkoutExercise) -> some View {
        ZStack(alignment: .bottomLeading) {
            AnimatedExerciseVisual(
                muscleGroup: exercise.targetMuscle,
                exerciseName: exercise.name,
                equipment: exercise.equipment,
                height: dynamicTypeSize.isAccessibilitySize ? 308 : 254
            )

            LinearGradient(
                colors: [
                    Color.black.opacity(0.00),
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                heroPills

                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.62)

                    exerciseMeta(exercise)
                }
            }
            .padding(16)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentPositionText), \(exercise.name), \(exercise.targetMuscle.title), \(exercise.equipment.title)")
    }

    private var heroPills: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                statusPill(title: currentPositionText, systemImage: "figure.strengthtraining.traditional")

                Spacer(minLength: 8)

                statusPill(title: viewModel.plan.title, systemImage: "list.bullet")
            }

            VStack(alignment: .leading, spacing: 8) {
                statusPill(title: currentPositionText, systemImage: "figure.strengthtraining.traditional")
                statusPill(title: viewModel.plan.title, systemImage: "list.bullet")
            }
        }
    }

    private func statusPill(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white.opacity(0.92))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(Color.black.opacity(0.48), in: Capsule())
    }

    @ViewBuilder
    private func exerciseMeta(_ exercise: WorkoutExercise) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 7) {
                heroMetaLabel(exercise.targetMuscle.title, systemImage: exercise.targetMuscle.icon)
                heroMetaLabel(exercise.equipment.title, systemImage: exercise.equipment.icon)
            }
        } else {
            HStack(spacing: 10) {
                heroMetaLabel(exercise.targetMuscle.title, systemImage: exercise.targetMuscle.icon)
                heroMetaLabel(exercise.equipment.title, systemImage: exercise.equipment.icon)
            }
        }
    }

    private func heroMetaLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.88))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
    }

    private func exerciseDetails(_ exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            metricGroup(exercise)

            ProgressView(value: positionProgress)
                .tint(Color.deltsAccent)
                .accessibilityLabel(currentPositionText)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.deltsWarning)
                    .frame(width: 24, height: 24)

                Text(exercise.formTip)
                    .font(.footnote)
                    .foregroundStyle(Color.deltsMutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func metricGroup(_ exercise: WorkoutExercise) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 12) {
                exerciseMetric(title: "Sets", value: "\(exercise.sets)", systemImage: "number")
                stripSeparator
                exerciseMetric(title: "Reps", value: exercise.reps, systemImage: "repeat", tint: .deltsInferno)
                stripSeparator
                exerciseMetric(title: "Rest", value: exercise.restDisplay, systemImage: "timer", tint: .deltsSecondaryAccent)
            }
        } else {
            HStack(spacing: 0) {
                exerciseMetric(title: "Sets", value: "\(exercise.sets)", systemImage: "number")
                metricDivider
                exerciseMetric(title: "Reps", value: exercise.reps, systemImage: "repeat", tint: .deltsInferno)
                metricDivider
                exerciseMetric(title: "Rest", value: exercise.restDisplay, systemImage: "timer", tint: .deltsSecondaryAccent)
            }
        }
    }

    private func standardSetLoggerRow(_ setIndex: Int) -> some View {
        HStack(alignment: .center, spacing: 10) {
            setNumberBadge(setIndex)

            setEntryField(
                title: "Weight",
                placeholder: "0",
                text: weightBinding(setIndex),
                keyboardType: .decimalPad,
                field: .weight(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex),
                accessibilityLabel: "Weight for set \(setIndex + 1)"
            )
            .layoutPriority(1)

            setEntryField(
                title: "Reps",
                placeholder: "0",
                text: repsBinding(setIndex),
                keyboardType: .numberPad,
                field: .reps(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex),
                accessibilityLabel: "Reps for set \(setIndex + 1)",
                alignment: .center
            )
            .frame(width: 88)

            setCompleteButton(setIndex)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }

    private func stackedSetLoggerRow(_ setIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                setNumberBadge(setIndex)

                Text("Set \(setIndex + 1)")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)

                Spacer(minLength: 8)

                setCompleteButton(setIndex)
            }

            setEntryFields(setIndex)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func setEntryFields(_ setIndex: Int) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                weightEntryField(setIndex)
                repsEntryField(setIndex)
            }
        } else {
            HStack(alignment: .top, spacing: 10) {
                weightEntryField(setIndex)
                repsEntryField(setIndex)
            }
        }
    }

    private func weightEntryField(_ setIndex: Int) -> some View {
        setEntryField(
            title: "Weight",
            placeholder: "0",
            text: weightBinding(setIndex),
            keyboardType: .decimalPad,
            field: .weight(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex),
            accessibilityLabel: "Weight for set \(setIndex + 1)"
        )
    }

    private func repsEntryField(_ setIndex: Int) -> some View {
        setEntryField(
            title: "Reps",
            placeholder: "0",
            text: repsBinding(setIndex),
            keyboardType: .numberPad,
            field: .reps(exerciseIndex: viewModel.currentExerciseIndex, setIndex: setIndex),
            accessibilityLabel: "Reps for set \(setIndex + 1)",
            alignment: .center
        )
    }

    private func setNumberBadge(_ setIndex: Int) -> some View {
        Text("\(setIndex + 1)")
            .font(.callout.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(isSetComplete(setIndex) ? Color.deltsSecondaryAccent : Color.deltsCharcoal)
            .frame(width: 38, height: 38)
            .background(
                isSetComplete(setIndex)
                    ? Color.deltsSecondaryAccent.opacity(0.14)
                    : Color.deltsPanel.opacity(0.42),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .accessibilityHidden(true)
    }

    private func setEntryField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType,
        field: ActiveWorkoutLogField,
        accessibilityLabel: String,
        alignment: TextAlignment = .leading
    ) -> some View {
        let isFocused = focusedField == field

        return VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textFieldStyle(.plain)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .monospacedDigit()
                .multilineTextAlignment(alignment)
                .focused($focusedField, equals: field)
                .accessibilityLabel(accessibilityLabel)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(Color.deltsPanel.opacity(isFocused ? 0.62 : 0.38), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isFocused ? Color.deltsAccent.opacity(0.78) : Color.deltsHairline.opacity(0.38), lineWidth: isFocused ? 1 : 0.5)
        }
    }

    private func setCompleteButton(_ setIndex: Int) -> some View {
        let complete = isSetComplete(setIndex)

        return Button {
            viewModel.toggleSet(setIndex)
        } label: {
            Image(systemName: complete ? "checkmark.circle.fill" : "circle")
                .font(.title3.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(complete ? Color.deltsSecondaryAccent : Color.deltsMutedText)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(complete ? "Mark set \(setIndex + 1) incomplete" : "Mark set \(setIndex + 1) complete")
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
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
        }
        .frame(maxWidth: .infinity, alignment: dynamicTypeSize.isAccessibilitySize ? .center : .leading)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.34))
            .frame(width: 0.5, height: 36)
            .padding(.horizontal, 10)
    }

    private var stripSeparator: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.34))
            .frame(height: 0.5)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.deltsInferno)
            Text("No exercises found")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var positionProgress: Double {
        guard !viewModel.exercises.isEmpty else { return 0 }
        return Double(viewModel.currentExerciseIndex + 1) / Double(viewModel.exercises.count)
    }

    private var currentPositionText: String {
        guard !viewModel.exercises.isEmpty else { return "Exercise 0 of 0" }
        return "Exercise \(viewModel.currentExerciseIndex + 1) of \(viewModel.exercises.count)"
    }

    private func goToNextExercise() {
        focusedField = nil
        resetRestTimer()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            viewModel.nextExercise()
        }
    }

    private func toggleRestTimer(defaultSeconds: Int) {
        guard defaultSeconds > 0 else { return }
        if restSecondsRemaining <= 0 {
            restSecondsRemaining = defaultSeconds
        }
        restTimerRunning.toggle()
    }

    private func resetRestTimer() {
        restTimerRunning = false
        restSecondsRemaining = 0
    }

    private func restTimerText(defaultSeconds: Int) -> String {
        let seconds = restSecondsRemaining > 0 ? restSecondsRemaining : defaultSeconds
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%d:%02d", minutes, remainder)
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
