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
    @Namespace private var indicatorNamespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(DeltsTab.allCases) { tab in
                let isSelected = selection == tab
                Button {
                    withAnimation(.snappy(duration: 0.28)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 19, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(isSelected ? Color.deltsElectricBlue : Color.deltsMutedText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.deltsElectricBlue.opacity(0.12))
                                .matchedGeometryEffect(id: "tab-selection", in: indicatorNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(7)
        .background(Color(uiColor: .systemBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .deltsLiquidBarSurface(cornerRadius: 28)
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.28), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 8)
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
