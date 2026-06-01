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
    let libraryCount: Int

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(workoutCount)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.deltsAccent)
                    .contentTransition(.numericText())

                Text("workout\(workoutCount == 1 ? "" : "s") planned")
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .foregroundStyle(Color.deltsMutedText)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.deltsAccent.opacity(0.10))
                        .frame(height: 10)

                    Capsule()
                        .fill(Color.deltsAccent)
                        .frame(width: progressWidth(totalWidth: geometry.size.width), height: 10)
                        .shadow(color: Color.deltsAccent.opacity(0.24), radius: 8, y: 3)
                        .animation(.spring(response: 0.8, dampingFraction: 0.75), value: setCount)
                }
            }
            .frame(height: 10)
            .padding(.horizontal, 24)

            HStack(spacing: 20) {
                HomeMetricCard(label: "Sets", current: setCount, goal: 24)
                HomeMetricCard(label: "Workouts", current: workoutCount, goal: 6)
                HomeMetricCard(label: "Library", current: libraryCount, goal: libraryCount)
            }
            .padding(.top, 22)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        guard setCount > 0 else { return 0 }
        return max(10, totalWidth * min(Double(setCount) / 24.0, 1.0))
    }
}

struct HomeMetricCard: View {
    let label: String
    let current: Int
    let goal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(current)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.deltsAccent)
                    .minimumScaleFactor(0.62)
                    .lineLimit(1)
                Text("/\(goal)")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .minimumScaleFactor(0.62)
                    .lineLimit(1)
            }

            Capsule()
                .fill(Color.deltsAccent.opacity(0.18))
                .frame(height: 7)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.deltsAccent)
                        .frame(width: progressWidth)
                }

            Text(label)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.deltsMutedText)
        }
    }

    private var progressWidth: CGFloat {
        guard goal > 0 else { return 0 }
        return CGFloat(min(Double(current) / Double(goal), 1.0)) * 74
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
        .background(Color.deltsPanel.opacity(0.36), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.44), lineWidth: 0.75)
        }
    }
}

struct PlannedExerciseRow: View {
    let exercise: PlannedRoutineExercise
    let focusedRepsExerciseID: FocusState<UUID?>.Binding
    let updateSets: (Int) -> Void
    let updateReps: (String) -> Void
    let openDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: openDetail) {
                HStack(spacing: 12) {
                    AnimatedExerciseVisual(
                        exerciseName: exercise.name,
                        imagePaths: exercise.imagePaths,
                        height: 62,
                        fillsWidth: false,
                        allowsDerivedImageLookup: false
                    )
                    .frame(width: 62, height: 62)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .clipped()
                    .layoutPriority(0)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(exercise.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.deltsCharcoal)
                            .lineLimit(2)

                        Text("\(exercise.primaryMuscles.joined(separator: ", ")) - \(exercise.rawEquipment) - \(exercise.rawLevel)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.deltsMutedText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Stepper(value: Binding(get: { exercise.sets }, set: updateSets), in: 1...12) {
                    Text("\(exercise.sets) set\(exercise.sets == 1 ? "" : "s")")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                }

                TextField("Reps", text: Binding(get: { exercise.reps }, set: updateReps))
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .multilineTextAlignment(.center)
                    .focused(focusedRepsExerciseID, equals: exercise.id)
                    .frame(width: 74, height: 38)
                    .background(Color.deltsPanel.opacity(0.34), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.deltsHairline.opacity(0.34), lineWidth: 0.5)
                    }

            }
        }
        .padding(.vertical, 6)
    }
}

struct WorkoutPickerSheet: View {
    @Binding var searchText: String
    @Binding var source: WorkoutPickerSource
    let pickerTitle: String
    let exercises: [ExerciseLibraryItem]
    let selectedExerciseIDs: Set<String>
    let savedExerciseIDs: Set<String>
    let onToggleSelection: (ExerciseLibraryItem) -> Void
    let onToggleSaved: (String) -> Void
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Source", selection: $source) {
                        ForEach(WorkoutPickerSource.allCases) { source in
                            Text(source.rawValue).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear)
                }

                Section {
                    if exercises.isEmpty {
                        Text(source == .saved ? "No saved workouts yet." : "No dataset workouts found.")
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
            .background(Color.deltsBackground)
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search workouts")
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
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
