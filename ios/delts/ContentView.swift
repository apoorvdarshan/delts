//
//  ContentView.swift
//  delts
//
//  Created by Apoorv Darshan on 22/05/26.
//

import SwiftUI

struct ContentView: View {
    init() {
        // Re-show onboarding on demand (testing) without touching any user data.
        if ProcessInfo.processInfo.arguments.contains("--delts-show-onboarding") {
            UserDefaults.standard.set(false, forKey: "delts_onboarding_complete")
        }
    }

    @State private var selectedTab: DeltsTab = .initialTab
    @StateObject private var updateChecker = AppUpdateChecker()
    @AppStorage(AppAppearance.storageKey) private var appAppearanceRaw = AppAppearance.system.rawValue
    @AppStorage(DeltsTheme.storageKey) private var deltsThemeRaw = DeltsTheme.lime.rawValue
    @AppStorage("delts_onboarding_complete") private var onboardingComplete = false

    private var appAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRaw) ?? .system
    }

    var body: some View {
        rootView
            .tint(Color.deltsAccent)
            .preferredColorScheme(appAppearance.preferredColorScheme)
            .id("\(appAppearanceRaw)-\(deltsThemeRaw)")
            .task {
                await updateChecker.checkForUpdatesIfNeeded()
            }
    }

    @ViewBuilder
    private var rootView: some View {
        if !onboardingComplete && !skipsOnboardingForLaunchArgs {
            OnboardingView()
        } else {
            tabRoot
        }
    }

    private var skipsOnboardingForLaunchArgs: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--delts-tab") || arguments.contains("--delts-skip-onboarding") {
            return true
        }
        let environment = ProcessInfo.processInfo.environment
        return environment["DELTS_INITIAL_TAB"] != nil || environment["DELTS_SKIP_ONBOARDING"] != nil
    }

    private var tabRoot: some View {
        TabView(selection: $selectedTab) {
            WorkoutsView()
                .tabItem { Label(DeltsTab.workouts.title, systemImage: DeltsTab.workouts.systemImage) }
                .tag(DeltsTab.workouts)

            SettingsView(updateChecker: updateChecker)
                .tabItem { Label(DeltsTab.settings.title, systemImage: DeltsTab.settings.systemImage) }
                .tag(DeltsTab.settings)
                .badge(updateChecker.isUpdateAvailable ? Text("") : nil)

            AboutView(updateChecker: updateChecker)
                .tabItem { Label(DeltsTab.about.title, systemImage: DeltsTab.about.systemImage) }
                .tag(DeltsTab.about)
        }
    }

}

private enum DeltsTab: String, CaseIterable, Identifiable {
    case workouts
    case settings
    case about

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

        return .workouts
    }

    var title: String {
        switch self {
        case .workouts: return String(localized: "Workouts")
        case .settings: return String(localized: "Settings")
        case .about: return String(localized: "About")
        }
    }

    var systemImage: String {
        switch self {
        case .workouts: return "list.clipboard.fill"
        case .settings: return "gearshape.fill"
        case .about: return "info.circle.fill"
        }
    }
}

#Preview {
    ContentView()
}
