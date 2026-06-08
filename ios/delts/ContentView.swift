//
//  ContentView.swift
//  delts
//
//  Created by Apoorv Darshan on 22/05/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @State private var selectedTab: DeltsTab = .initialTab
    @StateObject private var updateChecker = AppUpdateChecker()
    @AppStorage(AppAppearance.storageKey) private var appAppearanceRaw = AppAppearance.system.rawValue
    @AppStorage(DeltsTheme.storageKey) private var deltsThemeRaw = DeltsTheme.lime.rawValue

    private var appAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .system
    }

    var body: some View {
        rootView
            .tint(Color.deltsAccent)
            .preferredColorScheme(appAppearance.preferredColorScheme)
            .id("\(appAppearanceRaw)-\(deltsThemeRaw)")
            .task {
                ensureDefaultProfile()
                await updateChecker.checkForUpdatesIfNeeded()
            }
    }

    @ViewBuilder
    private var rootView: some View {
        if let scene = DeltsLaunchScene.initialScene {
            launchScene(scene)
        } else {
            tabRoot
        }
    }

    private var tabRoot: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label(DeltsTab.home.title, systemImage: DeltsTab.home.systemImage) }
                .tag(DeltsTab.home)

            WorkoutsView()
                .tabItem { Label(DeltsTab.workouts.title, systemImage: DeltsTab.workouts.systemImage) }
                .tag(DeltsTab.workouts)

            ProgressTabView()
                .tabItem { Label(DeltsTab.progress.title, systemImage: DeltsTab.progress.systemImage) }
                .tag(DeltsTab.progress)

            ProfileView(updateChecker: updateChecker)
                .tabItem { Label(DeltsTab.profile.title, systemImage: DeltsTab.profile.systemImage) }
                .tag(DeltsTab.profile)
                .badge(updateChecker.isUpdateAvailable ? Text("") : nil)
        }
    }

    @ViewBuilder
    private func launchScene(_ scene: DeltsLaunchScene) -> some View {
        switch scene {
        case .plan:
            PlanView()
        case .workout:
            NavigationStack {
                WorkoutPlanView(plan: DeltsPreviewWorkoutFactory.plan())
            }
        case .active:
            NavigationStack {
                ActiveWorkoutView(plan: DeltsPreviewWorkoutFactory.plan())
            }
        case .summary:
            NavigationStack {
                CompletedWorkoutDetailView(workout: DeltsPreviewWorkoutFactory.completedWorkout())
            }
        }
    }

    private func ensureDefaultProfile() {
        guard profiles.isEmpty else { return }
        modelContext.insert(UserProfile.defaultProfile())
        try? modelContext.save()
    }
}

private enum DeltsLaunchScene: String {
    case plan
    case workout
    case active
    case summary

    static var initialScene: DeltsLaunchScene? {
        let arguments = ProcessInfo.processInfo.arguments
        if let sceneFlagIndex = arguments.firstIndex(of: "--delts-scene"),
           arguments.indices.contains(arguments.index(after: sceneFlagIndex)),
           let scene = DeltsLaunchScene(rawValue: arguments[arguments.index(after: sceneFlagIndex)]) {
            return scene
        }

        if let sceneValue = ProcessInfo.processInfo.environment["DELTS_INITIAL_SCENE"],
           let scene = DeltsLaunchScene(rawValue: sceneValue) {
            return scene
        }

        return nil
    }
}

private enum DeltsPreviewWorkoutFactory {
    static func plan() -> WorkoutPlan {
        WorkoutPlan(
            title: "Chest Session",
            summary: "Press, fly, and finish with controlled volume.",
            muscleGroup: .chest,
            goal: .muscleGain,
            durationMinutes: 60,
            generatedByAI: false,
            exercises: [
                WorkoutExercise(
                    orderIndex: 0,
                    name: "Barbell Bench Press",
                    targetMuscle: .chest,
                    equipment: .barbell,
                    sets: 4,
                    reps: "6-8",
                    restSeconds: 90,
                    formTip: "Keep shoulder blades pinned and drive the bar in a steady path.",
                    difficulty: ExperienceLevel.intermediate.title
                ),
                WorkoutExercise(
                    orderIndex: 1,
                    name: "Incline Dumbbell Press",
                    targetMuscle: .chest,
                    equipment: .dumbbells,
                    sets: 3,
                    reps: "8-10",
                    restSeconds: 75,
                    formTip: "Lower with control and stop before the shoulders roll forward.",
                    difficulty: ExperienceLevel.intermediate.title
                ),
                WorkoutExercise(
                    orderIndex: 2,
                    name: "Cable Crossover",
                    targetMuscle: .chest,
                    equipment: .cableMachine,
                    sets: 3,
                    reps: "12-15",
                    restSeconds: 60,
                    formTip: "Move through the chest, not the elbows, and pause at the squeeze.",
                    difficulty: ExperienceLevel.intermediate.title
                )
            ]
        )
    }

    static func completedWorkout() -> CompletedWorkout {
        CompletedWorkout(
            title: "Chest Session",
            durationMinutes: 58,
            planSummary: "Press, fly, and finish with controlled volume.",
            exerciseLogs: [
                CompletedExerciseLog(
                    name: "Barbell Bench Press",
                    targetMuscle: MuscleGroup.chest.title,
                    equipment: Equipment.barbell.title,
                    sets: [
                        CompletedSetLog(setNumber: 1, completed: true, weight: "80", reps: "8", rpe: "7"),
                        CompletedSetLog(setNumber: 2, completed: true, weight: "85", reps: "7", rpe: "8"),
                        CompletedSetLog(setNumber: 3, completed: true, weight: "85", reps: "6", rpe: "8.5")
                    ]
                ),
                CompletedExerciseLog(
                    name: "Incline Dumbbell Press",
                    targetMuscle: MuscleGroup.chest.title,
                    equipment: Equipment.dumbbells.title,
                    sets: [
                        CompletedSetLog(setNumber: 1, completed: true, weight: "30", reps: "10", rpe: "7"),
                        CompletedSetLog(setNumber: 2, completed: true, weight: "30", reps: "9", rpe: "8"),
                        CompletedSetLog(setNumber: 3, completed: false, weight: "", reps: "")
                    ]
                )
            ]
        )
    }
}

private enum DeltsTab: String, CaseIterable, Identifiable {
    case home
    case workouts
    case progress
    case profile

    var id: String { rawValue }

    static var initialTab: DeltsTab {
        let arguments = ProcessInfo.processInfo.arguments
        if let tabFlagIndex = arguments.firstIndex(of: "--delts-tab"),
           arguments.indices.contains(arguments.index(after: tabFlagIndex)),
           let tab = DeltsTab(rawValue: arguments[arguments.index(after: tabFlagIndex)]) {
            return tab
        }

        if let tabValue = ProcessInfo.processInfo.environment["DELTS_INITIAL_TAB"],
           let tab = DeltsTab(rawValue: tabValue) {
            return tab
        }

        return .home
    }

    var title: String {
        switch self {
        case .home: return "Home"
        case .workouts: return "Workouts"
        case .progress: return "Progress"
        case .profile: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .workouts: return "list.clipboard.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .profile: return "gearshape.fill"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            UserProfile.self,
            Exercise.self,
            WorkoutPlan.self,
            WorkoutExercise.self,
            CompletedWorkout.self
        ], inMemory: true)
}
