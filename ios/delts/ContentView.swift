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

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            PlanView()
                .tabItem {
                    Label("Plan", systemImage: "sparkles")
                }

            EquipmentView()
                .tabItem {
                    Label("Equipment", systemImage: "dumbbell.fill")
                }

            WorkoutsView()
                .tabItem {
                    Label("Workouts", systemImage: "list.bullet.clipboard.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(Color.deltsElectricBlue)
        .preferredColorScheme(.dark)
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
