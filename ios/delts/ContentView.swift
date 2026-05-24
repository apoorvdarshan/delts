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
    @State private var selectedTab: DeltsTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label(DeltsTab.home.title, systemImage: DeltsTab.home.systemImage) }
                .tag(DeltsTab.home)

            WorkoutsView()
                .tabItem { Label(DeltsTab.workouts.title, systemImage: DeltsTab.workouts.systemImage) }
                .tag(DeltsTab.workouts)

            ProfileView()
                .tabItem { Label(DeltsTab.profile.title, systemImage: DeltsTab.profile.systemImage) }
                .tag(DeltsTab.profile)
        }
            .tint(Color.deltsAccent)
            .task {
                ensureDefaultProfile()
            }
    }

    private func ensureDefaultProfile() {
        guard profiles.isEmpty else { return }
        modelContext.insert(UserProfile.defaultProfile())
        try? modelContext.save()
    }
}

private enum DeltsTab: String, CaseIterable, Identifiable {
    case home
    case workouts
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Start"
        case .workouts: return "Workouts"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "play.fill"
        case .workouts: return "list.clipboard.fill"
        case .profile: return "person.fill"
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
