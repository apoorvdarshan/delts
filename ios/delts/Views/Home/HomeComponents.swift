import SwiftUI

struct WorkoutWeekStrip: View {
    @Binding var selectedDate: Date
    let workoutCountForDate: (Date) -> Int
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday = true
    @State private var hasScrolledToInitial = false

    private static let totalWeeks = 53
    private static let currentWeekIndex = totalWeeks - 1

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = weekStartsOnMonday ? 2 : 1
        return calendar
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<Self.totalWeeks, id: \.self) { weekIndex in
                        weekRow(for: weekIndex)
                            .containerRelativeFrame(.horizontal)
                            .id(weekIndex)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .onAppear {
                guard !hasScrolledToInitial else { return }
                hasScrolledToInitial = true
                proxy.scrollTo(weekIndex(for: selectedDate), anchor: .trailing)
            }
            .onChange(of: weekStartsOnMonday) { _, _ in
                proxy.scrollTo(Self.currentWeekIndex, anchor: .trailing)
            }
        }
    }

    private func weekRow(for weekIndex: Int) -> some View {
        let dates = weekDates(for: weekIndex)
        return HStack(spacing: 0) {
            ForEach(dates, id: \.self) { date in
                dayTile(for: date)
            }
        }
    }

    private func dayTile(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let workoutCount = workoutCountForDate(date)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.snappy(duration: 0.3)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 6) {
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsMutedText.opacity(0.62))

                Text(date.formatted(.dateTime.day()))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.deltsOnAccent : (isToday ? Color.deltsAccent : Color.deltsCharcoal))
                    .frame(width: 36, height: 36)
                    .background {
                        if isSelected {
                            Circle()
                                .fill(Color.deltsAccent)
                                .shadow(color: Color.deltsAccent.opacity(0.28), radius: 6, y: 3)
                        } else if isToday {
                            Circle()
                                .strokeBorder(Color.deltsAccent.opacity(0.35), lineWidth: 1.5)
                        }
                    }

                Circle()
                    .fill(workoutCount > 0 ? Color.deltsAccent : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func weekDates(for weekOffset: Int) -> [Date] {
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let daysBack = (weekday - calendar.firstWeekday + 7) % 7
        let startOfCurrentWeek = calendar.date(byAdding: .day, value: -daysBack, to: today) ?? today
        let offset = weekOffset - Self.currentWeekIndex
        let startOfWeek = calendar.date(byAdding: .weekOfYear, value: offset, to: startOfCurrentWeek) ?? startOfCurrentWeek
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private func weekIndex(for date: Date) -> Int {
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let daysBack = (weekday - calendar.firstWeekday + 7) % 7
        let startOfCurrentWeek = calendar.date(byAdding: .day, value: -daysBack, to: today) ?? today
        let components = calendar.dateComponents([.weekOfYear], from: startOfCurrentWeek, to: calendar.startOfDay(for: date))
        return Self.currentWeekIndex + (components.weekOfYear ?? 0)
    }
}

struct StartWorkoutHero: View {
    let workoutCount: Int
    let setCount: Int
    let repCount: Int
    let timerStartedAt: Date?
    let timerElapsedSeconds: Int
    let isTimerRunning: Bool
    let isTimerPaused: Bool
    let hasTimerSession: Bool
    let toggleTimer: () -> Void
    let stopTimer: () -> Void
    let discardTimer: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            HStack(spacing: 12) {
                Spacer(minLength: 0)

                HomeSessionTimerButton(
                    startedAt: timerStartedAt,
                    elapsedSeconds: timerElapsedSeconds,
                    isRunning: isTimerRunning,
                    isPaused: isTimerPaused,
                    hasSession: hasTimerSession,
                    action: toggleTimer
                )

                if isTimerPaused {
                    HomeSessionTimerSideControls(
                        stopTimer: stopTimer,
                        discardTimer: discardTimer
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }

                Spacer(minLength: 0)
            }
            .animation(.snappy(duration: 0.28), value: isTimerPaused)

            HomeSessionStatsStrip(
                setCount: setCount,
                workoutCount: workoutCount,
                repCount: repCount,
                calorieBurnText: "-- kcal"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }
}

struct HomeSessionTimerButton: View {
    let startedAt: Date?
    let elapsedSeconds: Int
    let isRunning: Bool
    let isPaused: Bool
    let hasSession: Bool
    let action: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Button(action: action) {
                VStack(spacing: 10) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.black.opacity(0.52), radius: 2, y: 1)
                        .frame(height: 34)

                    Text(displayText(at: context.date))
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                        .contentTransition(.numericText())
                        .monospacedDigit()
                        .lineLimit(1)
                        .shadow(color: Color.black.opacity(0.62), radius: 2, y: 1)
                }
                .frame(width: 156, height: 156)
                .background {
                    Image("timer_button_red")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 176, height: 176)
                        .shadow(color: Color.black.opacity(0.34), radius: 16, y: 8)
                }
            }
            .buttonStyle(HomeTimerButtonStyle(isRunning: isRunning))
            .accessibilityLabel(accessibilityLabel)
        }
    }

    private var accessibilityLabel: String {
        if isRunning { return "Pause workout timer" }
        if isPaused || hasSession { return "Resume workout timer" }
        return "Start workout timer"
    }

    private func displayText(at date: Date) -> String {
        ActiveWorkoutViewModel.elapsedDisplay(totalElapsedSeconds(at: date))
    }

    private func totalElapsedSeconds(at date: Date) -> Int {
        guard let startedAt else { return elapsedSeconds }
        return elapsedSeconds + max(0, Int(date.timeIntervalSince(startedAt)))
    }
}

private struct HomeSessionTimerSideControls: View {
    let stopTimer: () -> Void
    let discardTimer: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HomeTimerSideButton(
                title: "Stop",
                systemImage: "stop.fill",
                role: .stop,
                action: stopTimer
            )

            HomeTimerSideButton(
                title: "Discard",
                systemImage: "trash.fill",
                role: .discard,
                action: discardTimer
            )
        }
        .frame(width: 118)
    }
}

private struct HomeTimerSideButton: View {
    let title: String
    let systemImage: String
    let role: HomeTimerSideButtonStyle.Role
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(iconForeground)
                    .frame(width: 22, height: 22)
                    .background(iconBackground, in: Circle())

                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                Spacer(minLength: 0)
            }
            .padding(.leading, 7)
            .padding(.trailing, 8)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(HomeTimerSideButtonStyle(role: role))
        .accessibilityLabel(title)
    }

    private var iconForeground: Color {
        switch role {
        case .stop:
            return Color.deltsAccent
        case .discard:
            return Color.white
        }
    }

    private var iconBackground: Color {
        switch role {
        case .stop:
            return Color.deltsOnAccent.opacity(0.96)
        case .discard:
            return Color.red.opacity(0.88)
        }
    }
}

private struct HomeTimerSideButtonStyle: ButtonStyle {
    enum Role {
        case stop
        case discard
    }

    let role: Role

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .frame(height: 46)
            .background(configuration.isPressed ? pressedBackground : background, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(border, lineWidth: role == .stop ? 0.8 : 1)
            }
            .shadow(color: shadowColor, radius: role == .stop ? 7 : 0, x: 0, y: role == .stop ? 4 : 0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch role {
        case .stop:
            return Color.deltsOnAccent
        case .discard:
            return Color.red.opacity(0.92)
        }
    }

    private var background: Color {
        switch role {
        case .stop:
            return Color.deltsAccent
        case .discard:
            return Color.deltsCard.opacity(0.72)
        }
    }

    private var pressedBackground: Color {
        switch role {
        case .stop:
            return Color.deltsAccent.opacity(0.82)
        case .discard:
            return Color.red.opacity(0.10)
        }
    }

    private var border: Color {
        switch role {
        case .stop:
            return Color.deltsAccent.opacity(0.45)
        case .discard:
            return Color.red.opacity(0.42)
        }
    }

    private var shadowColor: Color {
        switch role {
        case .stop:
            return Color.deltsAccent.opacity(0.24)
        case .discard:
            return Color.clear
        }
    }
}

private struct HomeTimerButtonStyle: ButtonStyle {
    let isRunning: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : (isRunning ? 0.985 : 1))
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
            .animation(.snappy(duration: 0.18), value: isRunning)
    }
}

struct HomeSessionStatsStrip: View {
    let setCount: Int
    let workoutCount: Int
    let repCount: Int
    let calorieBurnText: String

    var body: some View {
        HStack(spacing: 0) {
            HomeMetricCard(
                label: "Sets",
                value: "\(setCount)",
                systemImage: "checklist",
                isActive: setCount > 0
            )

            HomeMetricDivider()

            HomeMetricCard(
                label: "Workouts",
                value: "\(workoutCount)",
                systemImage: "dumbbell.fill",
                isActive: workoutCount > 0
            )

            HomeMetricDivider()

            HomeMetricCard(
                label: "Reps",
                value: "\(repCount)",
                systemImage: "repeat",
                isActive: repCount > 0
            )

            HomeMetricDivider()

            HomeMetricCard(
                label: "Burn",
                value: calorieBurnText,
                systemImage: "flame.fill",
                isActive: false
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color.deltsPanel.opacity(0.84), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.72), lineWidth: 0.8)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 8)
    }
}

private struct HomeMetricDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.52))
            .frame(width: 1, height: 44)
            .padding(.horizontal, 2)
    }
}

struct HomeMetricCard: View {
    let label: String
    let value: String
    let systemImage: String
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(isActive ? Color.deltsAccent : Color.deltsMutedText.opacity(0.72))
                    .frame(width: 14, height: 14)

                Text(label)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(isActive ? Color.deltsAccent : Color.deltsCharcoal)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .padding(.horizontal, 7)
    }
}

struct EmptyRoutineRow: View {
    let splitTitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.deltsAccent)

            VStack(alignment: .leading, spacing: 3) {
                Text("No workouts logged")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                Text("Use + to pick \(splitTitle) workouts for this day")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
            }
        }
        .padding(12)
        .background(Color.deltsPanel.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.95), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 5)
    }
}

struct PlannedExerciseRow: View {
    let exercise: PlannedRoutineExercise
    let focusedRepsField: FocusState<PlannedSetFocus?>.Binding
    let updateSets: (Int) -> Void
    let updateSetReps: (Int, String) -> Void
    let updateSetRPE: (Int, String) -> Void
    let openDetail: () -> Void

    var body: some View {
        let setReps = exercise.normalizedSetReps
        let setRPE = exercise.normalizedSetRPE
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 8),
            count: setReps.count == 1 ? 1 : 2
        )

        VStack(alignment: .leading, spacing: 14) {
            Button(action: openDetail) {
                HStack(alignment: .center, spacing: 12) {
                    AnimatedExerciseVisual(
                        exerciseName: exercise.name,
                        imagePaths: exercise.imagePaths,
                        height: 64,
                        fillsWidth: false,
                        allowsDerivedImageLookup: false
                    )
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.deltsHairline.opacity(0.48), lineWidth: 0.7)
                    }
                    .clipped()
                    .layoutPriority(0)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.name)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.deltsCharcoal)
                            .lineLimit(2)

                        Text("\(exercise.primaryMuscles.joined(separator: ", ")) - \(exercise.rawEquipment) - \(exercise.rawLevel)")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.deltsMutedText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText.opacity(0.72))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Text("Sets")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.deltsMutedText)

                Stepper(value: Binding(get: { exercise.sets }, set: updateSets), in: 1...12) {
                    Text("\(exercise.sets) set\(exercise.sets == 1 ? "" : "s")")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.deltsCharcoal)
                }
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(Array(setReps.enumerated()), id: \.offset) { index, _ in
                    PlannedSetField(
                        exerciseID: exercise.id,
                        setIndex: index,
                        reps: Binding(
                            get: {
                                let values = exercise.normalizedSetReps
                                return values.indices.contains(index) ? values[index] : ""
                            },
                            set: { updateSetReps(index, $0) }
                        ),
                        rpe: Binding(
                            get: {
                                setRPE.indices.contains(index) ? setRPE[index] : ""
                            },
                            set: { updateSetRPE(index, $0) }
                        ),
                        focusedRepsField: focusedRepsField
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.deltsPanel, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.82), lineWidth: 0.8)
        }
        .shadow(color: Color.black.opacity(0.22), radius: 12, x: 0, y: 7)
    }
}

private struct PlannedSetField: View {
    let exerciseID: UUID
    let setIndex: Int
    @Binding var reps: String
    @Binding var rpe: String
    let focusedRepsField: FocusState<PlannedSetFocus?>.Binding

    var body: some View {
        let repsFocus = PlannedSetFocus(exerciseID: exerciseID, setIndex: setIndex, field: .reps)
        let rpeFocus = PlannedSetFocus(exerciseID: exerciseID, setIndex: setIndex, field: .rpe)

        VStack(alignment: .leading, spacing: 7) {
            Text("Set \(setIndex + 1)")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)

            HStack(spacing: 8) {
                PlannedSetValueField(
                    title: "Reps",
                    placeholder: "0",
                    text: $reps,
                    keyboardType: .numberPad,
                    focus: repsFocus,
                    focusedRepsField: focusedRepsField
                )

                PlannedSetValueField(
                    title: "RPE",
                    placeholder: "Opt",
                    text: $rpe,
                    keyboardType: .decimalPad,
                    focus: rpeFocus,
                    focusedRepsField: focusedRepsField
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minHeight: 76)
        .background(Color.deltsCard.opacity(0.78), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.48), lineWidth: 0.6)
        }
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .highPriorityGesture(
            TapGesture().onEnded {
                focusedRepsField.wrappedValue = repsFocus
            }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens set reps and RPE input")
    }
}

private struct PlannedSetValueField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let focus: PlannedSetFocus
    let focusedRepsField: FocusState<PlannedSetFocus?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)

            if #available(iOS 18.0, *) {
                PlannedSetSelectionTextField(
                    placeholder: placeholder,
                    text: $text,
                    keyboardType: keyboardType,
                    focus: focus,
                    focusedRepsField: focusedRepsField
                )
            } else {
                baseTextField
            }
        }
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
    }

    private var baseTextField: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .textFieldStyle(.plain)
            .font(.system(.subheadline, design: .rounded, weight: .bold).monospacedDigit())
            .foregroundStyle(Color.deltsCharcoal)
            .multilineTextAlignment(.leading)
            .focused(focusedRepsField, equals: focus)
    }
}

@available(iOS 18.0, *)
private struct PlannedSetSelectionTextField: View {
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let focus: PlannedSetFocus
    let focusedRepsField: FocusState<PlannedSetFocus?>.Binding
    @State private var selection: TextSelection?

    var body: some View {
        TextField(placeholder, text: $text, selection: $selection)
            .keyboardType(keyboardType)
            .textFieldStyle(.plain)
            .font(.system(.subheadline, design: .rounded, weight: .bold).monospacedDigit())
            .foregroundStyle(Color.deltsCharcoal)
            .multilineTextAlignment(.leading)
            .focused(focusedRepsField, equals: focus)
            .onTapGesture {
                moveCursorToEnd()
            }
            .onChange(of: focusedRepsField.wrappedValue) { _, value in
                guard value == focus else { return }
                moveCursorToEnd()
            }
    }

    private func moveCursorToEnd() {
        DispatchQueue.main.async {
            selection = TextSelection(insertionPoint: text.endIndex)
        }
    }
}

struct WorkoutPickerSheet: View {
    @Binding var searchText: String
    @Binding var source: WorkoutPickerSource
    @Binding var selectedLevels: Set<String>
    @Binding var selectedRawEquipment: Set<String>
    @Binding var selectedPrimaryMuscles: Set<String>
    @Binding var selectedSecondaryMuscles: Set<String>
    @Binding var selectedForces: Set<String>
    @Binding var selectedMechanics: Set<String>
    @Binding var selectedCategories: Set<String>
    @Binding var selectedSort: ExerciseLibrarySort
    let pickerTitle: String
    let showsSourcePicker: Bool
    let primaryFilterMuscles: Set<String>
    let hidesPrimaryFilter: Bool
    let targetPrimaryMuscles: Set<String>
    let limitsPrimaryToTargetMuscles: Bool
    let rawEquipmentOptions: [String]
    let exercises: [ExerciseLibraryItem]
    let selectedExerciseIDs: Set<String>
    let savedExerciseIDs: Set<String>
    let onToggleSelection: (ExerciseLibraryItem) -> Void
    let onToggleSaved: (String) -> Void
    let onDone: () -> Void

    private let service = ExerciseLibraryService.shared

    private var primaryFilterOptions: [String] {
        let baseOptions: [String]
        if primaryFilterMuscles.isEmpty {
            baseOptions = service.availablePrimaryMuscles
        } else {
            baseOptions = service.availablePrimaryMuscles.filter { primaryFilterMuscles.contains($0) }
        }
        guard limitsPrimaryToTargetMuscles else { return baseOptions }
        return baseOptions.filter { targetPrimaryMuscles.contains($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if showsSourcePicker {
                        Picker("Source", selection: $source) {
                            ForEach(WorkoutPickerSource.allCases) { source in
                                Text(source.rawValue).tag(source)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 4, trailing: 20))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    workoutFilterStrip
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 6, trailing: 20))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    workoutPickerHeaderControls
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    if exercises.isEmpty {
                        Text(!showsSourcePicker || source == .saved ? "No saved workouts yet." : "No dataset workouts found.")
                            .foregroundStyle(Color.deltsMutedText)
                            .listRowBackground(Color.deltsPanel.opacity(0.22))
                    } else {
                        ForEach(exercises.prefix(120)) { item in
                            WorkoutPickerRow(
                                item: item,
                                isSelected: selectedExerciseIDs.contains(item.id)
                            ) {
                                onToggleSelection(item)
                            }
                            .listRowBackground(Color.deltsPanel.opacity(selectedExerciseIDs.contains(item.id) ? 0.28 : 0.18))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    onToggleSaved(item.id)
                                } label: {
                                    Label(savedExerciseIDs.contains(item.id) ? "Unsave" : "Save", systemImage: savedExerciseIDs.contains(item.id) ? "bookmark.slash.fill" : "bookmark.fill")
                                }
                                .tint(Color.deltsAccent)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .contentMargins(.top, 0, for: .scrollContent)
            .background(Color.deltsBackground)
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search workouts")
            .listSectionSpacing(0)
            .navigationTitle("Add \(pickerTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.deltsAccent)
                }
            }
        }
        .onAppear {
            normalizePrimaryFilterSelection()
            normalizeEquipmentFilterSelection()
        }
        .onChange(of: primaryFilterMuscles) {
            normalizePrimaryFilterSelection()
        }
        .onChange(of: hidesPrimaryFilter) {
            normalizePrimaryFilterSelection()
        }
        .onChange(of: targetPrimaryMuscles) {
            normalizePrimaryFilterSelection()
        }
        .onChange(of: limitsPrimaryToTargetMuscles) {
            normalizePrimaryFilterSelection()
        }
        .onChange(of: rawEquipmentOptions) {
            normalizeEquipmentFilterSelection()
        }
    }

    private var hasActiveFilters: Bool {
        !searchText.isEmpty ||
            !selectedLevels.isEmpty ||
            !selectedRawEquipment.isEmpty ||
            !selectedPrimaryMuscles.isEmpty ||
            !selectedSecondaryMuscles.isEmpty ||
            !selectedForces.isEmpty ||
            !selectedMechanics.isEmpty ||
            !selectedCategories.isEmpty ||
            selectedSort != .name
    }

    private var workoutPickerHeaderControls: some View {
        HStack(spacing: 8) {
            Spacer()

            Button {
                resetFilters()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(hasActiveFilters ? Color.deltsInferno : Color.deltsMutedText)
                    .lineLimit(1)
                    .padding(.horizontal, 11)
                    .frame(height: 34)
                    .background((hasActiveFilters ? Color.deltsInferno : Color.deltsPanel).opacity(hasActiveFilters ? 0.10 : 0.22), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke((hasActiveFilters ? Color.deltsInferno : Color.deltsHairline).opacity(hasActiveFilters ? 0.28 : 0.24), lineWidth: 0.5)
                    }
            }
            .disabled(!hasActiveFilters)
            .buttonStyle(.plain)
            .deltsPressable()

            Menu {
                ForEach(ExerciseLibrarySort.allCases) { sort in
                    menuChoice(sort.title, isSelected: selectedSort == sort) {
                        selectedSort = sort
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(selectedSort == .name ? Color.deltsMutedText : Color.deltsAccent)
                    .lineLimit(1)
                    .padding(.horizontal, 11)
                    .frame(height: 34)
                    .background(Color.deltsPanel.opacity(selectedSort == .name ? 0.30 : 0.46), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke((selectedSort == .name ? Color.deltsHairline : Color.deltsAccent).opacity(0.32), lineWidth: 0.5)
                    }
            }
            .buttonStyle(.plain)
            .deltsPressable()
        }
    }

    private var workoutFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                if !hidesPrimaryFilter {
                    filterMenuPill(
                        title: "Primary",
                        value: primaryFilterTitle,
                        systemImage: "scope"
                    ) {
                        menuChoice(allPrimaryMenuTitle, isSelected: selectedPrimaryMuscles.isEmpty) {
                            selectedPrimaryMuscles.removeAll()
                        }
                        ForEach(primaryFilterOptions, id: \.self) { muscle in
                            muscleMenuChoice(muscle, muscles: [muscle], isSelected: selectedPrimaryMuscles.contains(muscle)) {
                                selectedPrimaryMuscles = toggledSelection(muscle, in: selectedPrimaryMuscles)
                            }
                        }
                    }
                }

                filterMenuPill(
                    title: "Secondary",
                    value: selectionTitle(selectedSecondaryMuscles),
                    systemImage: "scope"
                ) {
                        menuChoice("All Secondary", isSelected: selectedSecondaryMuscles.isEmpty) {
                            selectedSecondaryMuscles.removeAll()
                        }
                        ForEach(service.availableSecondaryMuscles, id: \.self) { muscle in
                            muscleMenuChoice(muscle, muscles: [muscle], isSelected: selectedSecondaryMuscles.contains(muscle)) {
                                selectedSecondaryMuscles = toggledSelection(muscle, in: selectedSecondaryMuscles)
                            }
                        }
                    }

                filterMenuPill(
                    title: "Equipment",
                    value: equipmentFilterTitle,
                    systemImage: "dumbbell.fill"
                ) {
                    menuChoice(allEquipmentMenuTitle, isSelected: selectedRawEquipment.isEmpty) {
                        selectedRawEquipment.removeAll()
                    }
                    ForEach(rawEquipmentOptions, id: \.self) { equipment in
                        menuChoice(equipment, isSelected: selectedRawEquipment.contains(equipment)) {
                            selectedRawEquipment = toggledSelection(equipment, in: selectedRawEquipment)
                        }
                    }
                }

                filterMenuPill(
                    title: "Level",
                    value: selectionTitle(selectedLevels),
                    systemImage: "chart.bar.fill"
                ) {
                    menuChoice("All Levels", isSelected: selectedLevels.isEmpty) {
                        selectedLevels.removeAll()
                    }
                    ForEach(service.availableLevels, id: \.self) { level in
                        menuChoice(level, isSelected: selectedLevels.contains(level)) {
                            selectedLevels = toggledSelection(level, in: selectedLevels)
                        }
                    }
                }

                filterMenuPill(
                    title: "Force",
                    value: selectionTitle(selectedForces),
                    systemImage: "arrow.left.arrow.right"
                ) {
                    menuChoice("All Forces", isSelected: selectedForces.isEmpty) {
                        selectedForces.removeAll()
                    }
                    ForEach(service.availableForces, id: \.self) { force in
                        menuChoice(force, isSelected: selectedForces.contains(force)) {
                            selectedForces = toggledSelection(force, in: selectedForces)
                        }
                    }
                }

                filterMenuPill(
                    title: "Mechanic",
                    value: selectionTitle(selectedMechanics),
                    systemImage: "gearshape"
                ) {
                    menuChoice("All Mechanics", isSelected: selectedMechanics.isEmpty) {
                        selectedMechanics.removeAll()
                    }
                    ForEach(service.availableMechanics, id: \.self) { mechanic in
                        menuChoice(mechanic, isSelected: selectedMechanics.contains(mechanic)) {
                            selectedMechanics = toggledSelection(mechanic, in: selectedMechanics)
                        }
                    }
                }

                filterMenuPill(
                    title: "Category",
                    value: selectionTitle(selectedCategories),
                    systemImage: "tag"
                ) {
                    menuChoice("All Categories", isSelected: selectedCategories.isEmpty) {
                        selectedCategories.removeAll()
                    }
                    ForEach(service.availableCategoryCounts) { categoryCount in
                        menuChoice(categoryCount.category, isSelected: selectedCategories.contains(categoryCount.category)) {
                            selectedCategories = toggledSelection(categoryCount.category, in: selectedCategories)
                        }
                    }
                }
            }
            .padding(.vertical, 1)
        }
    }

    private var equipmentFilterTitle: String {
        if selectedRawEquipment.isEmpty {
            return "All \(rawEquipmentOptions.count)"
        }
        return selectionTitle(selectedRawEquipment)
    }

    private var primaryFilterTitle: String {
        if selectedPrimaryMuscles.isEmpty {
            return "All \(primaryFilterOptions.count)"
        }
        return selectionTitle(selectedPrimaryMuscles)
    }

    private var allPrimaryMenuTitle: String {
        "All Primary (\(primaryFilterOptions.count))"
    }

    private var allEquipmentMenuTitle: String {
        "All Equipment (\(rawEquipmentOptions.count))"
    }

    private func resetFilters() {
        searchText = ""
        selectedLevels.removeAll()
        selectedRawEquipment.removeAll()
        selectedPrimaryMuscles.removeAll()
        selectedSecondaryMuscles.removeAll()
        selectedForces.removeAll()
        selectedMechanics.removeAll()
        selectedCategories.removeAll()
        selectedSort = .name
    }

    private func normalizePrimaryFilterSelection() {
        if hidesPrimaryFilter {
            selectedPrimaryMuscles.removeAll()
            return
        }

        let validOptions = Set(primaryFilterOptions)
        guard !validOptions.isEmpty else {
            selectedPrimaryMuscles.removeAll()
            return
        }
        selectedPrimaryMuscles = selectedPrimaryMuscles.intersection(validOptions)
    }

    private func normalizeEquipmentFilterSelection() {
        let validOptions = Set(rawEquipmentOptions)
        selectedRawEquipment = selectedRawEquipment.intersection(validOptions)
    }

    private func selectionTitle(_ selection: Set<String>) -> String {
        if selection.isEmpty { return "All" }
        if selection.count == 1 { return selection.first ?? "All" }
        return "\(selection.count) selected"
    }

    private func toggledSelection(_ value: String, in selection: Set<String>) -> Set<String> {
        var next = selection
        if next.contains(value) {
            next.remove(value)
        } else {
            next.insert(value)
        }
        return next
    }

    private func filterMenuPill<Content: View>(
        title: String,
        value: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            WorkoutPickerFilterPill(title: title, value: value, systemImage: systemImage)
        }
        .menuActionDismissBehavior(.disabled)
        .deltsPressable()
    }

    private func menuChoice(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if isSelected {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
    }

    private func muscleMenuChoice(
        _ title: String,
        muscles: Set<String>,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            if isSelected {
                Label(title, systemImage: "checkmark")
            } else {
                Label(title, image: MuscleGlyphAsset.name(title: title, muscles: muscles))
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct WorkoutPickerFilterPill: View {
    let title: String
    let value: String
    let systemImage: String

    private var isDefaultValue: Bool {
        value == "All" || value == "Name"
    }

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isDefaultValue ? Color.deltsSecondaryAccent : Color.deltsAccent)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
                .padding(.leading, 1)
        }
        .padding(.horizontal, 12)
        .frame(minWidth: 112, minHeight: 46, alignment: .leading)
        .background(
            Color.deltsPanel.opacity(isDefaultValue ? 0.30 : 0.46),
            in: RoundedRectangle(cornerRadius: 17, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(
                    (isDefaultValue ? Color.deltsHairline : Color.deltsAccent).opacity(isDefaultValue ? 0.30 : 0.42),
                    lineWidth: 0.5
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

struct WorkoutPickerRow: View {
    let item: ExerciseLibraryItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AnimatedExerciseVisual(
                    exerciseName: item.name,
                    imagePaths: item.imagePaths,
                    height: 58,
                    fillsWidth: false,
                    allowsDerivedImageLookup: false
                )
                .frame(width: 76, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .clipped()
                .layoutPriority(0)

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.deltsCharcoal)
                        .lineLimit(2)

                    Text("\(item.primaryMusclesTitle) - \(item.rawEquipment)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.deltsMutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsMutedText)
                    .frame(width: 34, height: 34)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
