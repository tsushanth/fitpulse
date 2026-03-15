//
//  ContentView.swift
//  FitPulse
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(HealthKitService.self) private var healthKitService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedTab") private var selectedTab = 0

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                MainTabView(selectedTab: $selectedTab)
            }
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            WorkoutsView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.run")
                }
                .tag(1)

            BodyMetricsView()
                .tabItem {
                    Label("Body", systemImage: "figure.stand")
                }
                .tag(2)

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.fitPulseGreen)
    }
}

// MARK: - Color Extension
extension Color {
    static let fitPulseGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let fitPulseBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
    static let fitPulsePurple = Color(red: 0.6, green: 0.3, blue: 0.9)
    static let fitPulseOrange = Color(red: 1.0, green: 0.55, blue: 0.0)
    static let fitPulseRed = Color(red: 0.95, green: 0.25, blue: 0.25)
    static let cardBackground = Color(.secondarySystemBackground)
}
