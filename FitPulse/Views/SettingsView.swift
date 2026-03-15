//
//  SettingsView.swift
//  FitPulse
//
//  App settings and configuration
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(StoreKitManager.self) private var storeKitManager
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [UserGoal]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("userName") private var userName = ""
    @AppStorage("userHeightCm") private var userHeightCm: Double = 170

    @State private var showPaywall = false
    @State private var showResetAlert = false
    @State private var workoutReminderEnabled = false
    @State private var workoutReminderHour: Double = 8
    @State private var sleepReminderEnabled = false
    @State private var sleepReminderHour: Double = 22

    private var currentGoals: UserGoal? { goals.first }

    var body: some View {
        NavigationStack {
            Form {
                // Premium
                premiumSection

                // Profile
                profileSection

                // Goals
                goalsSection

                // Notifications
                notificationsSection

                // Health Data
                healthDataSection

                // App Info
                appInfoSection

                // Danger Zone
                dangerSection
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Reset All Data", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                resetAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all workouts, body metrics, and sleep data. This action cannot be undone.")
        }
    }

    private var premiumSection: some View {
        Section {
            if storeKitManager.isPremium {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.fitPulseOrange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FitPulse Premium")
                            .font(.headline)
                        Text("All features unlocked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("Active")
                        .font(.caption.bold())
                        .foregroundColor(.fitPulseGreen)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.fitPulseOrange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Premium")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Unlock advanced analytics & more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var profileSection: some View {
        Section("Profile") {
            HStack {
                Text("Name")
                Spacer()
                TextField("Your name", text: $userName)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Height")
                    Spacer()
                    Text("\(Int(userHeightCm)) cm")
                        .foregroundColor(.secondary)
                }
                Slider(value: $userHeightCm, in: 140...220, step: 1)
                    .tint(.fitPulseGreen)
            }
        }
    }

    @ViewBuilder
    private var goalsSection: some View {
        Section("Daily Goals") {
            NavigationLink {
                GoalsEditView()
            } label: {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.fitPulseGreen)
                    Text("Edit Goals")
                    Spacer()
                    if let goals = currentGoals {
                        Text("\(goals.dailyStepGoal.formatted()) steps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: $workoutReminderEnabled) {
                Label("Workout Reminder", systemImage: "bell.fill")
            }
            .onChange(of: workoutReminderEnabled) { _, enabled in
                notificationManager.updateWorkoutReminder(
                    enabled: enabled,
                    hour: Int(workoutReminderHour),
                    minute: 0
                )
            }

            if workoutReminderEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reminder Time: \(Int(workoutReminderHour)):00")
                        .font(.subheadline)
                    Slider(value: $workoutReminderHour, in: 5...22, step: 1)
                        .tint(.fitPulseGreen)
                }
            }

            Toggle(isOn: $sleepReminderEnabled) {
                Label("Sleep Reminder", systemImage: "moon.fill")
            }
            .onChange(of: sleepReminderEnabled) { _, enabled in
                notificationManager.updateSleepReminder(
                    enabled: enabled,
                    hour: Int(sleepReminderHour),
                    minute: 0
                )
            }
        }
    }

    private var healthDataSection: some View {
        Section("Health Data") {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.fitPulseRed)
                Text("HealthKit")
                Spacer()
                Text(healthKitService.isAuthorized ? "Connected" : "Not Connected")
                    .font(.caption)
                    .foregroundColor(healthKitService.isAuthorized ? .fitPulseGreen : .secondary)
            }

            if !healthKitService.isAuthorized {
                Button {
                    Task {
                        await healthKitService.requestAuthorization()
                    }
                } label: {
                    Label("Connect HealthKit", systemImage: "link")
                        .foregroundColor(.fitPulseGreen)
                }
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Health Settings", systemImage: "arrow.up.right.square")
                    .foregroundColor(.primary)
            }
        }
    }

    private var appInfoSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text("1")
                    .foregroundColor(.secondary)
            }

            Link(destination: URL(string: "https://fitpulse.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            Link(destination: URL(string: "https://fitpulse.app/terms")!) {
                Label("Terms of Use", systemImage: "doc.text.fill")
            }

            Button {
                if let url = URL(string: "https://apps.apple.com/app/fitpulse") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Rate FitPulse", systemImage: "star.fill")
                    .foregroundColor(.fitPulseOrange)
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Label("Reset All Data", systemImage: "trash.fill")
            }
        }
    }

    private func resetAllData() {
        try? modelContext.delete(model: Workout.self)
        try? modelContext.delete(model: BodyMetric.self)
        try? modelContext.delete(model: SleepSession.self)
        try? modelContext.delete(model: UserGoal.self)
    }
}

// MARK: - Goals Edit View
struct GoalsEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [UserGoal]
    @Environment(\.dismiss) private var dismiss

    @State private var stepGoal: Double = 10000
    @State private var calorieGoal: Double = 500
    @State private var exerciseGoal: Double = 30
    @State private var standGoal: Double = 12
    @State private var weeklyWorkoutGoal: Double = 5

    var body: some View {
        Form {
            Section("Steps") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Steps: \(Int(stepGoal).formatted())")
                    Slider(value: $stepGoal, in: 2000...25000, step: 500)
                        .tint(.fitPulseGreen)
                }
            }

            Section("Calories") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Calories: \(Int(calorieGoal)) kcal")
                    Slider(value: $calorieGoal, in: 100...1500, step: 50)
                        .tint(.fitPulseRed)
                }
            }

            Section("Exercise") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercise Minutes: \(Int(exerciseGoal)) min")
                    Slider(value: $exerciseGoal, in: 10...120, step: 5)
                        .tint(.fitPulseOrange)
                }
            }

            Section("Stand") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stand Hours: \(Int(standGoal)) hrs")
                    Slider(value: $standGoal, in: 6...16, step: 1)
                        .tint(.fitPulseBlue)
                }
            }

            Section("Workouts") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Workouts: \(Int(weeklyWorkoutGoal))")
                    Slider(value: $weeklyWorkoutGoal, in: 1...14, step: 1)
                        .tint(.fitPulsePurple)
                }
            }
        }
        .navigationTitle("Edit Goals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveGoals()
                }
                .bold()
            }
        }
        .onAppear {
            if let goal = goals.first {
                stepGoal = Double(goal.dailyStepGoal)
                calorieGoal = goal.dailyCalorieGoal
                exerciseGoal = goal.dailyExerciseMinutes
                standGoal = goal.dailyStandHours
                weeklyWorkoutGoal = Double(goal.weeklyWorkoutGoal)
            }
        }
    }

    private func saveGoals() {
        if let existing = goals.first {
            existing.dailyStepGoal = Int(stepGoal)
            existing.dailyCalorieGoal = calorieGoal
            existing.dailyExerciseMinutes = exerciseGoal
            existing.dailyStandHours = standGoal
            existing.weeklyWorkoutGoal = Int(weeklyWorkoutGoal)
            existing.updatedAt = Date()
        } else {
            let goal = UserGoal(
                dailyStepGoal: Int(stepGoal),
                dailyCalorieGoal: calorieGoal,
                dailyExerciseMinutes: exerciseGoal,
                dailyStandHours: standGoal,
                weeklyWorkoutGoal: Int(weeklyWorkoutGoal)
            )
            modelContext.insert(goal)
        }
        AnalyticsService.shared.track(.goalSet(type: "all"))
        dismiss()
    }
}
