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
        selectedRoot
            .safeAreaInset(edge: .bottom) {
                DeltsFloatingTabBar(selection: $selectedTab)
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    .background(Color.clear)
            }
            .task {
                ensureDefaultProfile()
            }
    }

    @ViewBuilder
    private var selectedRoot: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .plan:
            PlanView()
        case .equipment:
            EquipmentView()
        case .workouts:
            WorkoutsView()
        case .profile:
            ProfileView()
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
    case plan
    case equipment
    case workouts
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .plan: return "Plan"
        case .equipment: return "Equipment"
        case .workouts: return "Workouts"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .plan: return "sparkles"
        case .equipment: return "dumbbell.fill"
        case .workouts: return "list.clipboard.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

private struct DeltsFloatingTabBar: View {
    @Binding var selection: DeltsTab

    var body: some View {
        DeltsGlassGroup(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(DeltsTab.allCases) { tab in
                    let isSelected = selection == tab
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            selection = tab
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 20, weight: .bold))
                            Text(tab.title)
                                .font(.caption2.weight(.bold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(isSelected ? Color.deltsInk : Color.deltsMutedText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            Group {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(Color.deltsGold.opacity(0.95))
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(isSelected ? Color.deltsInk.opacity(0.72) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(7)
        .background(Color.deltsCard, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.deltsInk.opacity(0.72),
                            Color.deltsInferno.opacity(0.36),
                            Color.deltsElectricBlue.opacity(0.36)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.deltsInk.opacity(0.14), radius: 12, x: 0, y: 6)
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
