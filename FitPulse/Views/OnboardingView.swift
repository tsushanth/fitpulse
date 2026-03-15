//
//  OnboardingView.swift
//  FitPulse
//
//  App onboarding flow
//

import SwiftUI

struct OnboardingView: View {
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(NotificationManager.self) private var notificationManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentPage = 0

    private let pages = OnboardingPage.allPages

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.12, blue: 0.2), Color(red: 0.1, green: 0.2, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip Button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            currentPage = pages.count - 1
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                    }
                }

                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page Indicator + Button
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? Color.fitPulseGreen : Color.white.opacity(0.3))
                                .frame(width: currentPage == index ? 24 : 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }

                    if currentPage == pages.count - 1 {
                        // Permissions + Get Started
                        VStack(spacing: 12) {
                            Button {
                                Task {
                                    await healthKitService.requestAuthorization()
                                    await notificationManager.requestAuthorization()
                                    AnalyticsService.shared.track(.healthKitConnected)
                                    hasCompletedOnboarding = true
                                    AnalyticsService.shared.track(.onboardingCompleted)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "heart.fill")
                                    Text("Connect Health Data")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.fitPulseGreen)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .font(.headline)
                            }

                            Button("Skip for Now") {
                                hasCompletedOnboarding = true
                                AnalyticsService.shared.track(.onboardingCompleted)
                            }
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        }
                    } else {
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            HStack {
                                Text("Continue")
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.fitPulseGreen)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .font(.headline)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundColor(page.color)
            }

            // Text
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 8)
            }

            // Feature Bullets
            VStack(spacing: 10) {
                ForEach(page.bullets, id: \.self) { bullet in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(page.color)
                            .font(.subheadline)
                        Text(bullet)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let bullets: [String]

    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to FitPulse",
            description: "Your comprehensive health and activity tracker. Built for the way you live.",
            icon: "heart.fill",
            color: .fitPulseGreen,
            bullets: [
                "Track steps, calories & activity rings",
                "Log 20+ workout types",
                "Monitor sleep quality",
                "Body metrics & BMI tracking",
            ]
        ),
        OnboardingPage(
            title: "Activity Rings",
            description: "Close your Move, Exercise, and Stand rings every day to build healthy habits.",
            icon: "figure.run.circle.fill",
            color: .fitPulseRed,
            bullets: [
                "Move: burn active calories",
                "Exercise: get 30 min of activity",
                "Stand: stand for 12 hours",
                "Celebrate when all rings close!",
            ]
        ),
        OnboardingPage(
            title: "HealthKit Integration",
            description: "FitPulse reads and writes to Apple Health so your data is always in sync.",
            icon: "heart.text.square.fill",
            color: .fitPulseBlue,
            bullets: [
                "Auto-sync steps & workouts",
                "Heart rate monitoring",
                "Sleep stage analysis",
                "Secure & private — data stays on device",
            ]
        ),
        OnboardingPage(
            title: "Ready to Start?",
            description: "Grant access to your health data to unlock the full power of FitPulse.",
            icon: "checkmark.shield.fill",
            color: .fitPulseGreen,
            bullets: [
                "Your data never leaves your device",
                "HealthKit keeps everything secure",
                "Turn off access anytime in Settings",
                "Free to use with optional Premium",
            ]
        ),
    ]
}
