//
//  ContentView.swift
//  delts
//
//  Created by Apoorv Darshan on 22/05/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: DeltsTab = .initialTab

    var body: some View {
        tabRoot
            .tint(Color.deltsAccent)
    }

    private var tabRoot: some View {
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
    }
}

private enum DeltsTab: String, CaseIterable, Identifiable {
    case home
    case workouts
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
}
